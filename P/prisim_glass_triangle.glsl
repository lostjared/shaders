#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;

// High-fidelity spectral helper for the rainbow
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
    
    // --- GEOMETRY CALCULATION ---
    // Apex is at (0.5, 1.0) -> Top Center
    // Base spans from (0.0, 0.0) to (1.0, 0.0) -> Bottom corners
    
    // Check if we are inside the triangle wedge:
    // The slope of the sides is y = 1 - 2*abs(x - 0.5)
    float wedge = 1.0 - 2.0 * abs(uv.x - 0.5);
    
    // Define the "glass" area
    if (uv.y < wedge && uv.y > 0.0) {
        // --- INSIDE THE GLASS ---
        vec3 accumulatedColor = vec3(0.0);
        float dispersion = 0.12; 
        int samples = 24; 
        
        // Refraction vector: Light bends away from the top apex
        vec2 refractDir = normalize(uv - vec2(0.5, 1.0));

        for (int i = 0; i < samples; i++) {
            float w = float(i) / float(samples - 1);
            float shift = (w - 0.5) * dispersion;
            
            // Apply refraction shift
            vec2 sampleUV = uv + (refractDir * shift);
            
            accumulatedColor += texture(samp, clamp(sampleUV, 0.0, 1.0)).rgb * spectrum(w);
        }
        
        // Brightness and subtle glass tint
        vec3 finalRGB = accumulatedColor / (float(samples) * 0.5);
        finalRGB *= 1.1; 
        finalRGB += vec3(0.03, 0.04, 0.05); 
        
        color = vec4(finalRGB, 1.0);

        // Add a highlight along the slanted edges
        float edge = smoothstep(0.015, 0.0, abs(uv.y - wedge));
        color.rgb += edge * 0.4;

    } else {
        // --- OUTSIDE THE GLASS ---
        color = texture(samp, uv);
    }
}