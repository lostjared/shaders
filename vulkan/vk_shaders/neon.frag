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
#define value_alpha_b ext.custom_uniforms[1].w
#define value_alpha_g ext.custom_uniforms[1].z
#define value_alpha_r ext.custom_uniforms[1].y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;











vec3 overlayBlend(vec3 base, vec3 blend, float opacity) {
    vec3 c2 = blend * 2.0;
    vec3 c1 = 1.0 - 2.0 * (1.0 - blend);
    vec3 result = mix(base * c2, c1, step(0.5, base));
    return mix(base, result, opacity);
}

void main(void) {
    vec2 uv = tc;
    vec2 center = vec2(0.5, 0.5);
    vec2 normCoord = 2.0 * (uv - center);
    float dist = length(normCoord);
    float angle = atan(normCoord.y, normCoord.x) + time_f * (5.0 + amp_low * 10.0);
    float spiral = cos((10.0 + amp_mid * 10.0) * dist - angle);
    float mask = smoothstep(0.1, 0.2, abs(spiral) - dist * 0.5);
    vec3 neonPurple = vec3(value_alpha_r, value_alpha_g, value_alpha_b);
    vec3 originalTexture = texture(samp, uv).rgb;
    vec3 blendedColor = overlayBlend(originalTexture, neonPurple, mask);

    // --- Audio Reactivity: direct output modulation ---
    float _ab = clamp(amp_peak, 0.0, 1.0);
    float _abass = clamp(amp_low, 0.0, 1.0);
    blendedColor *= 1.0 + _ab * 0.6;
    blendedColor = mix(blendedColor, blendedColor * vec3(1.0 + _abass * 0.3, 1.0 - _abass * 0.15, 1.0 + clamp(amp_high, 0.0, 1.0) * 0.25), _ab);
    // --- End Audio Reactivity ---

    color = vec4(blendedColor, 1.0);
}
