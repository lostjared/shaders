#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

void main(void) {
    // Smooth amplitude controls how many echo layers blend
    float layers = 2.0 + amp_smooth * 6.0;
    int numLayers = int(clamp(layers, 2.0, 8.0));

    vec3 col = vec3(0.0);
    float totalWeight = 0.0;

    for (int i = 0; i < 8; i++) {
        if (i >= numLayers)
            break;

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
