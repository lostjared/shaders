#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;

// High-fidelity spectral helper for the rainbow smear
vec3 spectrum(float w) {
    vec3 c;
    if (w < 0.2)
        c = mix(vec3(1.0, 0.0, 1.0), vec3(0.0, 0.0, 1.0), w * 5.0);
    else if (w < 0.4)
        c = mix(vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 0.0), (w - 0.2) * 5.0);
    else if (w < 0.6)
        c = mix(vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), (w - 0.4) * 5.0);
    else if (w < 0.8)
        c = mix(vec3(1.0, 1.0, 0.0), vec3(1.0, 0.0, 0.0), (w - 0.6) * 5.0);
    else
        c = vec3(1.0, 0.0, 0.0);
    return c;
}

void main(void) {
    vec2 uv = tc;
    vec2 refractDir;

    // --- TRIANGLE STRIP SELECTION ---
    // Dividing the screen into 3 prism regions without visual borders
    float edge1 = 2.0 * uv.x;        // Line from (0,0) to (0.5, 1)
    float edge2 = -2.0 * uv.x + 2.0; // Line from (1,0) to (0.5, 1)

    if (uv.y > edge1) {
        // Top Left Prism: Refracts away from the top-left corner
        refractDir = normalize(uv - vec2(0.0, 1.0));
    } else if (uv.y > edge2) {
        // Top Right Prism: Refracts away from the top-right corner
        refractDir = normalize(uv - vec2(1.0, 1.0));
    } else {
        // Center/Bottom Prism: Refracts away from the bottom center
        refractDir = normalize(uv - vec2(0.5, 0.0));
    }

    // --- SPECTRAL DISPERSION ---
    vec3 accumulatedColor = vec3(0.0);
    float dispersion = 0.08;
    int samples = 20;

    for (int i = 0; i < samples; i++) {
        float w = float(i) / float(samples - 1);
        float shift = (w - 0.5) * dispersion;

        // Chromatic shift based on the specific prism's refraction vector
        vec2 sampleUV = uv + (refractDir * shift);
        accumulatedColor += texture(samp, clamp(sampleUV, 0.0, 1.0)).rgb * spectrum(w);
    }

    // Brightness normalization and subtle glass depth (no white lines)
    vec3 finalRGB = accumulatedColor / (float(samples) * 0.48);
    finalRGB += vec3(0.015, 0.02, 0.03);

    color = vec4(finalRGB, 1.0);
}