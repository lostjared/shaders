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
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    // 1. Center and normalize coordinates
    vec2 uv = (tc * 2.0 - 1.0);
    uv.x *= iResolution.x / iResolution.y; // Maintain aspect ratio
    
    // 2. Fractal parameters
    float zoom = sin(time_f * 0.2) * 0.5 + 1.5;
    vec3 fractalCol = vec3(0.0);
    float scale = 1.0;

    // 3. The Iterative Fold (The "Fractal" part)
    // We loop to create layers of self-similarity
    for (int i = 0; i < 6; i++) {
        // Folding space: mirroring the UVs creates symmetrical complexity
        uv = abs(uv) - 0.5; 
        
        // Rotation over time to create a "Kaleidoscope" effect
        float a = time_f * 0.3;
        float s = sin(a), c = cos(a);
        uv *= mat2(c, -s, s, c);
        
        // Scaling space inward
        uv *= 1.2;
        scale *= 1.2;

        // Calculate a "distance" based on the warped coordinates
        float d = length(uv);
        
        // Add glowing edges based on your original 'spoke' logic
        float glow = 0.01 / abs(sin(d * 8.0 - time_f) / 8.0);
        fractalCol += glow * vec3(0.2, 0.5, 1.0) / scale;
    }

    // 4. Texture Mapping
    // Use the warped UVs to sample the texture for a "infinite mirror" look
    vec4 texColor = texture(samp, fract(uv + time_f * 0.1));
    
    // 5. Combine original glow logic with fractal structure
    vec3 finalRGB = texColor.rgb * fractalCol;
    
    // Subtle vignette
    finalRGB *= smoothstep(1.5, 0.5, length(tc * 2.0 - 1.0));

    color = vec4(finalRGB, 1.0);
}