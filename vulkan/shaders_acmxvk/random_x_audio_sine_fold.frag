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
    vec2 uv = tc;

    // Bass drives sine fold amplitude
    float foldStrength = 0.01 + amp_low * 0.06;
    int iters = 2 + int(amp_rms * 4.0);

    for (int i = 0; i < 6; i++) {
        if (i >= iters) break;
        float fi = float(i);
        float freq = 6.0 + fi * 2.3 + amp_mid * 4.0;
        float speed = 0.9 + fi * 0.4 + amp_mid * 1.0;
        uv.x += foldStrength * sin(uv.y * freq + time_f * speed);
        uv.y += foldStrength * cos(uv.x * (5.0 + fi * 1.7) + time_f * (1.1 + fi * 0.3));
    }

    uv = abs(mod(uv, 2.0) - 1.0);

    // Treble chromatic split along fold
    float chroma = amp_high * 0.02;
    float r = texture(samp, clamp(uv + vec2(chroma, 0.0), 0.0, 1.0)).r;
    float g = texture(samp, clamp(uv, 0.0, 1.0)).g;
    float b = texture(samp, clamp(uv - vec2(chroma, 0.0), 0.0, 1.0)).b;

    vec3 col = vec3(r, g, b);

    // Smooth brightness
    col *= 1.0 + amp_smooth * 0.25;

    // Peak flash
    col += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
