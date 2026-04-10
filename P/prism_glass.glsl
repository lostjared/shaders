#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;

// Helper to create a spectral color from a 0.0-1.0 range
vec3 spectrum(float w) {
    vec3 c;
    if (w < 0.2) c = mix(vec3(1,0,1), vec3(0,0,1), w * 5.0);      // Violet to Blue
    else if (w < 0.4) c = mix(vec3(0,0,1), vec3(0,1,0), (w-0.2) * 5.0); // Blue to Green
    else if (w < 0.6) c = mix(vec3(0,1,0), vec3(1,1,0), (w-0.4) * 5.0); // Green to Yellow
    else if (w < 0.8) c = mix(vec3(1,1,0), vec3(1,0,0), (w-0.6) * 5.0); // Yellow to Red
    else c = vec3(1,0,0);
    return c;
}

// Signed Distance Function for an equilateral triangle
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
    vec2 p = (tc - 0.5) * iResolution.xy / iResolution.y;
    
    // Prism Parameters
    float prismSize = 0.3;
    float dispersion = 0.08; // How much the light "spreads"
    int samples = 12;        // Higher = smoother rainbow
    
    float d = sdTriangle(p, prismSize);

    if (d < 0.0) {
        // We are inside the prism!
        vec3 accumulatedColor = vec3(0.0);
        float totalWeight = 0.0;
        
        // Direction of refraction (usually away from the apex)
        vec2 refractDir = normalize(p - vec2(0.0, -0.1));

        for (int i = 0; i < samples; i++) {
            float w = float(i) / float(samples - 1);
            
            // Each "wavelength" refracts at a slightly different offset
            // Dispersion math: Offset = (index of refraction - 1)
            float shift = (w - 0.5) * dispersion;
            vec2 sampleUV = uv + refractDir * shift;
            
            vec3 spec = spectrum(w);
            accumulatedColor += texture(samp, clamp(sampleUV, 0.0, 1.0)).rgb * spec;
            totalWeight += 1.3; // Slight boost for brightness
        }
        
        color = vec4(accumulatedColor / (float(samples) * 0.5), 1.0);
        
        // Add a subtle glass reflection/tint
        color.rgb += vec3(0.05, 0.07, 0.1); 
    } else {
        // Outside the prism
        color = texture(samp, uv);
        
        // Add a subtle "edge" highlight
        float edge = smoothstep(0.01, 0.0, abs(d));
        color.rgb += edge * 0.4;
    }
}