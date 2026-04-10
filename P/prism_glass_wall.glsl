#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;

// High-fidelity spectral helper
vec3 spectrum(float w) {
    vec3 c;
    if (w < 0.2) c = mix(vec3(1.0, 0.0, 1.0), vec3(0.0, 0.0, 1.0), w * 5.0);
    else if (w < 0.4) c = mix(vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 0.0), (w - 0.2) * 5.0);
    else if (w < 0.6) c = mix(vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), (w - 0.4) * 5.0);
    else if (w < 0.8) c = mix(vec3(1.0, 1.0, 0.0), vec3(1.0, 0.0, 0.0), (w - 0.6) * 5.0);
    else c = vec3(1.0, 0.0, 0.0);
    return c;
}

void main(void) {
    vec2 uv = tc;
    vec2 refractDir;
    
    // --- TRIANGLE STRIP LOGIC ---
    // We divide the 1.0x1.0 UV space into 3 regions:
    // 1. Top-Left Triangle
    // 2. Top-Right Triangle
    // 3. Large Center-Bottom Triangle
    
    float edge1 = 2.0 * uv.x;          // Line from (0,0) to (0.5, 1)
    float edge2 = -2.0 * uv.x + 2.0;   // Line from (1,0) to (0.5, 1)

    // Determine which prism we are in and its refraction "apex"
    if (uv.y > edge1) {
        // Prism 1: Top Left
        refractDir = normalize(uv - vec2(0.0, 1.0));
    } else if (uv.y > edge2) {
        // Prism 2: Top Right
        refractDir = normalize(uv - vec2(1.0, 1.0));
    } else {
        // Prism 3: Center Bottom
        refractDir = normalize(uv - vec2(0.5, 0.0));
    }

    // --- SPECTRAL DISPERSION LOOP ---
    vec3 accumulatedColor = vec3(0.0);
    float dispersion = 0.07; 
    int samples = 18;

    for (int i = 0; i < samples; i++) {
        float w = float(i) / float(samples - 1);
        float shift = (w - 0.5) * dispersion;
        
        // Sample texture with chromatic offset
        vec2 sampleUV = uv + (refractDir * shift);
        accumulatedColor += texture(samp, clamp(sampleUV, 0.0, 1.0)).rgb * spectrum(w);
    }

    // Normalize and add glass depth
    vec3 finalRGB = accumulatedColor / (float(samples) * 0.5);
    finalRGB += vec3(0.02, 0.03, 0.04); 
    
    // --- EDGE HIGHLIGHTS ---
    // Add thin white lines at the boundaries to show the "cuts" in the glass
    float line1 = smoothstep(0.005, 0.0, abs(uv.y - edge1));
    float line2 = smoothstep(0.005, 0.0, abs(uv.y - edge2));
    finalRGB += (line1 + line2) * 0.5;

    color = vec4(finalRGB, 1.0);
}