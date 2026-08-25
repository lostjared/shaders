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
    // Smooth amplitude controls how many echo layers blend
    float layers = 2.0 + amp_smooth * 6.0;
    int numLayers = int(clamp(layers, 2.0, 8.0));

    vec3 col = vec3(0.0);
    float totalWeight = 0.0;

    for (int i = 0; i < 8; i++) {
        if (i >= numLayers) break;

        float fi = float(i);
        float weight = 1.0 / (1.0 + fi * 0.5);

        // Each layer zooms slightly based on bass
        float zoom = 1.0 + fi * (0.05 + amp_low * 0.03);
        vec2 echoUV = (tc - 0.5) * zoom + 0.5;

        // Mids shift each layer sideways
        echoUV.x += fi * amp_mid * 0.01 * sin(time_f + fi);
        echoUV.y += fi * amp_mid * 0.008 * cos(time_f * 0.7 + fi);

        echoUV = clamp(echoUV, 0.0, 1.0);
        col += texture(samp, echoUV).rgb * weight;
        totalWeight += weight;
    }

    col /= totalWeight;

    // Treble adds color separation per layer
    float trebleTint = amp_high * 0.08;
    col.r += trebleTint * sin(time_f * 2.0);
    col.b += trebleTint * cos(time_f * 1.5);

    // Peak brightness
    col += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
