#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define iamp ext.u1.z
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;










void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    // Convert to polar coordinates
    // Mids warp the angle
    angle += amp_mid * sin(dist * 8.0 - time_f * 2.0) * 1.5;

    // Bass warps the radius
    dist += amp_low * 0.15 * sin(angle * 3.0 + time_f * 3.0);
    dist *= 1.0 + amp_low * 0.3 * cos(time_f * 2.0);

    // Map back from polar
    vec2 warped = vec2(cos(angle), sin(angle)) * dist;
    warped.x /= aspect;
    warped += 0.5;

    // Treble adds micro-turbulence
    warped.x += amp_high * 0.005 * sin(warped.y * 80.0 + time_f * 10.0);
    warped.y += amp_high * 0.004 * cos(warped.x * 60.0 + time_f * 8.0);

    warped = clamp(warped, 0.0, 1.0);
    vec4 tex = texture(samp, warped);

    // RMS adds radial color shift
    float hshift = amp_rms * 0.1;
    tex.r += hshift * sin(angle);
    tex.b += hshift * cos(angle);

    // Smooth vignette that opens on smooth amp
    float vign = smoothstep(1.2, 0.3 + amp_smooth * 0.4, dist);
    tex.rgb *= vign;

    // Peak flash
    tex.rgb += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = tex;
}
