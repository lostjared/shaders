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

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main() {
    // 1. Center and fix aspect ratio
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= iResolution.x / iResolution.y;
    
    // 2. Deep Fractal Setup
    // 'p' is our moving point, 'c' is the constant based on mouse or time
    vec2 p = uv;
    float iters = 0.0;
    const float max_iters = 64.0;
    
    // Smoothly zoom in and out over time
    float zoom = pow(0.5, mod(time_f * 0.5, 10.0));
    p *= zoom;

    // 3. The Escape-Time Loop (The "Deep" part)
    // We iterate the function: z = z^2 + c
    for(float i = 0.0; i < max_iters; i++) {
        // Space folding (Abs creates symmetry, like your old x%2 check but infinite)
        p = abs(p) / dot(p, p) - vec2(0.8, 0.5 + 0.1 * sin(time_f * 0.3));
        
        if (length(p) > 20.0) break;
        iters++;
    }

    // 4. Color Logic (Integrating your original style)
    // Use the iteration count to pick a color depth
    float normIters = iters / max_iters;
    vec4 texColor = texture(samp, tc + p * 0.02); // Distorted texture lookup
    
    vec3 fractalColor;
    fractalColor.r = normIters * 2.0;
    fractalColor.g = sin(iters * 0.5 + time_f);
    fractalColor.b = length(p) * 0.1;

    // Apply your swapping/inversion logic
    float temp = fractalColor.r;
    fractalColor.r = fractalColor.b;
    fractalColor.b = temp;

    // Final output with your signature sin-time oscillation
    vec3 finalColor = (sin(time_f) > 0.0) ? vec3(1.0) - fractalColor : fractalColor;
    
    // Mix with original texture for a "ghostly" fractal overlay
    vec3 composite = mix(texColor.rgb, finalColor, 0.7);
    
    color = vec4(sin(composite * time_f), 1.0);
}