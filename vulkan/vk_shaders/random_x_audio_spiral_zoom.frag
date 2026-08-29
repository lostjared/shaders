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

    // Bass drives logarithmic spiral zoom
    float zoomSpeed = 1.0 + amp_low * 5.0;
    float spiralAngle = angle + log(dist + 0.01) * (3.0 + amp_mid * 4.0) - time_f * zoomSpeed;

    // RMS adds radial breathing
    float breathe = 1.0 + amp_rms * 0.4 * sin(time_f * 2.5);
    dist *= breathe;

    vec2 spiralUV = vec2(
        fract(spiralAngle / 6.28318 + 0.5),
        fract(log(dist + 0.01) * 2.0 + time_f * 0.5)
    );

    vec4 tex = texture(samp, spiralUV);

    // Treble adds concentric ring emphasis
    float ring = sin(dist * (30.0 + amp_high * 40.0) - time_f * 8.0);
    ring = smoothstep(0.8, 1.0, ring) * amp_high * 0.4;
    tex.rgb += ring;

    // Center vignette inverts with peaks
    float vign = smoothstep(1.5, 0.2, dist);
    vign = mix(vign, 1.0, amp_peak * 0.5);
    tex.rgb *= vign;

    // Peak flash
    tex.rgb += smoothstep(0.7, 1.0, amp_peak) * 0.2;

    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
