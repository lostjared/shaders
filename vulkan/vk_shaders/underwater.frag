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
    float t = time_f;
    vec2 uv = tc;

    vec2 p = uv * 2.0 - 1.0;
    float r2 = dot(p, p);
    p += p * r2 * 0.035 * sin(t * 0.4);
    uv = p * 0.5 + 0.5;

    vec2 d1 = vec2(sin(uv.y * 12.0 - t * 2.0), cos(uv.x * 12.0 + t * 1.6)) * (0.015 + amp_low * 0.03);
    vec2 d2 = vec2(sin((uv.x + uv.y) * 24.0 + t * 1.2), -cos((uv.x - uv.y) * 24.0 - t * 1.8)) * (0.009 + amp_mid * 0.02);
    vec2 d3 = vec2(cos(uv.y * 40.0 + t * 3.5), sin(uv.x * 40.0 - t * 3.0)) * (0.003 + amp_high * 0.01);

    uv += d1 + d2 + d3;
    uv = clamp(uv, 0.0, 1.0);

    color = texture(samp, uv);

    // --- Audio Reactivity: direct output modulation ---
    float _ab = clamp(amp_peak, 0.0, 1.0);
    float _abass = clamp(amp_low, 0.0, 1.0);
    color.rgb *= 1.0 + _ab * 0.6;
    color.rgb = mix(color.rgb, color.rgb * vec3(1.0 + _abass * 0.3, 1.0 - _abass * 0.15, 1.0 + clamp(amp_high, 0.0, 1.0) * 0.25), _ab);
    // --- End Audio Reactivity ---

}
