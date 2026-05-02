#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;

// High-fidelity spectral helper for smooth rainbow gradients
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

    // --- QUAD REFRACTION LOGIC ---
    // Instead of triangle edges, we use the center of the screen (0.5, 0.5)
    // as the "apex" of the refraction.
    vec2 center = vec2(0.5, 0.5);
    vec2 dir = uv - center;
    float dist = length(dir);

    // Normalize the refraction direction
    vec2 refractDir = normalize(dir);

    // --- SPECTRAL DISPERSION ---
    vec3 accumulatedColor = vec3(0.0);

    // dispersion: how far the colors spread
    // We scale it by 'dist' so the center is clear and edges are heavily refracted
    float dispersionBase = 0.09;
    float dispersion = dispersionBase * dist;

    int samples = 24; // High sample count for a smooth, glassy look

    for (int i = 0; i < samples; i++) {
        float w = float(i) / float(samples - 1);

        // Calculate the shift for this specific "wavelength"
        float shift = (w - 0.5) * dispersion;

        // Sample with the offset
        vec2 sampleUV = uv + (refractDir * shift);

        // Use clamp to prevent "wrap-around" artifacts at screen edges
        accumulatedColor += texture(samp, clamp(sampleUV, 0.0, 1.0)).rgb * spectrum(w);
    }

    // --- FINAL COLOR BALANCING ---
    // Normalize by samples and add a touch of "glass brilliance"
    vec3 finalRGB = accumulatedColor / (float(samples) * 0.5);
    finalRGB *= 1.05; // Subtle brightness boost

    // Optional: Very slight darkening at the corners to simulate light falloff in thick glass
    finalRGB *= 1.0 - (dist * 0.1);

    color = vec4(finalRGB, 1.0);
}