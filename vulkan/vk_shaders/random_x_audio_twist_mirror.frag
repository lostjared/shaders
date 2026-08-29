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










vec2 mirrorWrap(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    // Mids drive twist strength
    float twistStrength = 5.0 + amp_mid * 20.0;
    float twistAngle = (1.0 - smoothstep(0.0, 1.0, dist)) * twistStrength * sin(time_f * (0.3 + amp_mid));

    angle += twistAngle;

    // Apply mirror after twist
    vec2 twisted = vec2(cos(angle), sin(angle)) * dist;
    twisted.x /= aspect;
    twisted += 0.5;

    // Bass mirror fold count
    float foldIntensity = 1.0 + amp_low * 3.0;
    vec2 mirrored = mirrorWrap(twisted * foldIntensity);

    // Treble micro distortion
    mirrored.x += amp_high * 0.008 * sin(mirrored.y * 50.0 + time_f * 8.0);
    mirrored.y += amp_high * 0.006 * cos(mirrored.x * 40.0 + time_f * 6.0);

    vec4 tex = texture(samp, clamp(mirrored, 0.0, 1.0));

    // RMS color enhancement
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.2, 0.9, 1.1), amp_rms * 0.4);

    // Peak flash
    tex.rgb += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    // Smooth vignette
    float vign = smoothstep(1.2, 0.3 + amp_smooth * 0.3, dist);
    tex.rgb *= vign;

    color = tex;
}
