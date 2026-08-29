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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;









void main() {
    vec2 uv = tc;
    vec2 center = vec2(0.5, 0.5);
    vec2 offset = uv - center;

    float ripple = sin(length(offset) * (20.0 + amp_mid * 15.0) - time_f * 5.0) * (0.05 + amp_low * 0.1);
    float angle = atan(offset.y, offset.x) + ripple * sin(time_f);
    float radius = length(offset);
    vec2 swirlUV = center + radius * vec2(cos(angle), sin(angle));
    float pulse = (0.2 + amp_low * 0.3) * sin(time_f * 3.0);
    swirlUV += pulse * normalize(offset);
    vec4 texColor = texture(samp, swirlUV);
    vec3 shiftedColor = texColor.rgb * (0.8 + 0.2 * sin(time_f * 2.0));

    // --- Audio Reactivity: direct output modulation ---
    float _ab = clamp(amp_peak, 0.0, 1.0);
    float _abass = clamp(amp_low, 0.0, 1.0);
    shiftedColor *= 1.0 + _ab * 0.6;
    shiftedColor = mix(shiftedColor, shiftedColor * vec3(1.0 + _abass * 0.3, 1.0 - _abass * 0.15, 1.0 + clamp(amp_high, 0.0, 1.0) * 0.25), _ab);
    // --- End Audio Reactivity ---

    color = vec4(shiftedColor, texColor.a);
}
