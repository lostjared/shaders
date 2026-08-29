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










vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float dist = length(uv);

    // Concentric rings - each frequency band gets its own ring set
    float bassRing = sin(dist * (15.0 + amp_low * 25.0) - time_f * 3.0) * 0.5 + 0.5;
    float midRing = sin(dist * (25.0 + amp_mid * 20.0) - time_f * 5.0 + 1.0) * 0.5 + 0.5;
    float highRing = sin(dist * (40.0 + amp_high * 30.0) - time_f * 8.0 + 2.0) * 0.5 + 0.5;

    // Color each band
    vec3 bassColor = vec3(1.0, 0.2, 0.1) * bassRing * amp_low;
    vec3 midColor = vec3(0.1, 1.0, 0.3) * midRing * amp_mid;
    vec3 highColor = vec3(0.2, 0.3, 1.0) * highRing * amp_high;

    vec3 rings = bassColor + midColor + highColor;

    // Blend with source texture
    vec3 tex = texture(samp, tc).rgb;
    float blend = 0.3 + amp_rms * 0.4;
    vec3 col = mix(tex, tex + rings, blend);

    // Radial displacement from combined ring energy
    float displacement = (bassRing * amp_low + midRing * amp_mid) * 0.02;
    vec2 dispUV = tc + normalize(uv + 0.001) * displacement;
    dispUV = clamp(dispUV, 0.0, 1.0);
    vec3 dispTex = texture(samp, dispUV).rgb;
    col = mix(col, dispTex, 0.3);

    // Peak flash
    col += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
