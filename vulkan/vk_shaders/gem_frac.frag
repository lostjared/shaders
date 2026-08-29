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
#define alpha ext.u0.x
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;




void main(void) {
    // 1. Center and Normalize UVs
    vec2 uv = (tc * iResolution - 0.5 * iResolution) / iResolution.y;
    vec2 uv0 = uv; // Store original UV for distance effects
    vec3 finalColor = vec3(0.0);
    
    float t = time_f * 0.2;

    // 2. Iterative Fractal Loop
    for (float i = 0.0; i < 4.0; i++) {
        // Space folding (The "Fractal" part)
        uv = fract(uv * 1.5) - 0.5;

        float d = length(uv) * exp(-length(uv0));

        // 3. Incorporating your original trig-based color logic
        float angle = atan(uv.y, uv.x) + (t + i);
        
        vec3 col = vec3(
            sin(angle * 3.0 + i * 1.2),
            sin(angle * 4.0 + i * 1.5),
            sin(angle * 5.0 + i * 1.8)
        );
        
        // Use a variation of your wave/pingpong logic for contrast
        d = sin(d * 8.0 + t) / 8.0;
        d = abs(d);
        d = pow(0.01 / d, 1.2); // Create a "neon" glow effect

        finalColor += col * d;
    }

    // 4. Mix with texture as per your original design
    vec3 texColor = texture(samp, tc).rgb;
    vec3 result = mix(finalColor, texColor, 0.7);
    
    color = vec4(result, alpha);
}