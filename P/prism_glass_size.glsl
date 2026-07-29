#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;

// Spectrum helper for realistic light splitting
vec3 spectrum(float w) {
    vec3 c;
    if (w < 0.2) c = mix(vec3(1,0,1), vec3(0,0,1), w * 5.0);
    else if (w < 0.4) c = mix(vec3(0,0,1), vec3(0,1,0), (w-0.2) * 5.0);
    else if (w < 0.6) c = mix(vec3(0,1,0), vec3(1,1,0), (w-0.4) * 5.0);
    else if (w < 0.8) c = mix(vec3(1,1,0), vec3(1,0,0), (w-0.6) * 5.0);
    else c = vec3(1,0,0);
    return c;
}

// Equilateral triangle SDF scaled for screen space
float sdTriangle(vec2 p, float r) {
    const float k = sqrt(3.0);
    p.x = abs(p.x) - r;
    p.y = p.y + r/k;
    if (p.x + k*p.y > 0.0) p = vec2(p.x - k*p.y, -k*p.x - p.y) / 2.0;
    p.x -= clamp(p.x, -2.0*r, 0.0);
    return -length(p) * sign(p.y);
}

void main(void) {
    vec2 uv = tc;
    // Normalize coordinates to -1.0 to 1.0, accounting for aspect ratio
    vec2 p = (tc - 0.5) * 2.0;
    p.x *= iResolution.x / iResolution.y;
    
    // SCALE: 0.9 fills most of the height of the window
    float prismSize = 0.9; 
    
    // EFFECT SETTINGS
    float dispersion = 0.12; // Increased for the larger size
    int samples = 16;        // Increased for smoothness
    
    float d = sdTriangle(p, prismSize);

    if (d < 0.0) {
        vec3 accumulatedColor = vec3(0.0);
        float totalWeight = 0.0;
        
        // Refraction vector: Light "bends" toward the base of the triangle
        vec2 refractDir = normalize(vec2(p.x, p.y + 0.5));

        for (int i = 0; i < samples; i++) {
            float w = float(i) / float(samples - 1);
            float shift = (w - 0.5) * dispersion;
            
            // Apply a slight distortion curve to the refraction
            vec2 sampleUV = uv + (refractDir * shift * (1.0 - abs(d)));
            
            vec3 spec = spectrum(w);
            accumulatedColor += texture(samp, clamp(sampleUV, 0.0, 1.0)).rgb * spec;
            totalWeight += 1.0;
        }
        
        // Normalize and add a slight glass "sheen"
        vec3 finalRGB = accumulatedColor / (float(samples) * 0.45);
        finalRGB += vec3(0.02, 0.03, 0.05); 
        color = vec4(finalRGB, 1.0);
        
    } else {
        color = texture(samp, uv);
        
        // Subtle outer glow/edge definition
        float edge = smoothstep(0.02, 0.0, abs(d));
        color.rgb += edge * 0.3;
    }
}