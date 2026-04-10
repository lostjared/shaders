#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;

// Enhanced spectral helper for more "neon" brilliance
vec3 spectrum(float w) {
    vec3 c;
    if (w < 0.2) c = mix(vec3(1.0, 0.0, 1.0), vec3(0.0, 0.0, 1.0), w * 5.0);
    else if (w < 0.4) c = mix(vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 0.0), (w - 0.2) * 5.0);
    else if (w < 0.6) c = mix(vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), (w - 0.4) * 5.0);
    else if (w < 0.8) c = mix(vec3(1.0, 1.0, 0.0), vec3(1.0, 0.0, 0.0), (w - 0.6) * 5.0);
    else c = vec3(1.0, 0.0, 0.0);
    // Boost saturation
    return pow(c, vec3(0.8)); 
}

void main(void) {
    vec2 uv = tc;
    vec2 center = vec2(0.5, 0.5);
    vec2 dir = uv - center;
    float dist = length(dir);
    vec2 refractDir = normalize(dir);
    
    // --- INTENSITY SETTINGS ---
    float dispersionBase = 0.18; // Increased for a wider rainbow
    float dispersion = dispersionBase * dist; 
    int samples = 30; // More samples to handle the higher dispersion smoothly

    vec3 accumulatedColor = vec3(0.0);
    float maxBrightness = 0.0;

    // --- SPECTRAL SAMPLES ---
    for (int i = 0; i < samples; i++) {
        float w = float(i) / float(samples - 1);
        float shift = (w - 0.5) * dispersion;
        
        vec2 sampleUV = uv + (refractDir * shift);
        vec3 tex = texture(samp, clamp(sampleUV, 0.0, 1.0)).rgb;
        
        // Track brightness to help with the "glow"
        maxBrightness = max(maxBrightness, length(tex));
        
        accumulatedColor += tex * spectrum(w);
    }

    // Normalize and boost the "vibrancy"
    vec3 finalRGB = accumulatedColor / (float(samples) * 0.45);
    finalRGB = pow(finalRGB, vec3(0.9)); // Slight Gamma curve for "pop"

    // --- SPECULAR REFLECTION (THE GLINT) ---
    // Simulate a light source at the top-left
    vec2 lightPos = vec2(0.2, 0.8);
    float lightDist = length(uv - lightPos);
    
    // Create a "hotspot" for the reflection
    float reflection = pow(max(1.0 - lightDist, 0.0), 12.0) * 0.6;
    
    // Add a secondary "streak" reflection across the glass
    float streak = pow(max(1.0 - abs(uv.x + uv.y - 1.0), 0.0), 40.0) * 0.3;
    
    // Mix reflection into the final image
    finalRGB += (reflection + streak);

    // Subtle edge darkening to make the center "bloom"
    finalRGB *= 1.1 - (dist * 0.2);

    color = vec4(finalRGB, 1.0);
}