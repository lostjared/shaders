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




vec2 mirror(vec2 uv) {
    return abs(fract(uv * 0.5 + 0.5) * 2.0 - 1.0);
}

void main(void) {

    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= iResolution.x / iResolution.y;
    float iter = 0.0;
    float max_iter = 6.0;
    float time_pulse = sin(time_f * 0.2) * 0.5 + 0.5;

    for (float i = 0.0; i < max_iter; i++) {
        uv = abs(uv) - 0.5;
        
        float angle = time_f * 0.1 + i * 0.5;
        float s = sin(angle), c = cos(angle);
        uv *= mat2(c, -s, s, c);
        
        // Scale space: This creates the "infinite zoom" feel
        uv *= 1.1 + 0.1 * time_pulse;
        iter = i;
    }

    // 3. Texture Sampling with Fractal Distortion
    // We use the final warped UV to sample the texture
    vec2 fractal_tc = mirror(uv);
    vec4 texColor = texture(samp, fractal_tc);

    // 4. Color Logic (Evolved from your colorShift)
    // We use the iteration depth 'iter' to modulate colors
    vec3 fractalCol = 0.5 + 0.5 * cos(vec3(0.0, 2.0, 4.0) + length(uv) + time_f);
    
    // Mix the original texture with the mathematical fractal glow
    vec3 finalRGB = mix(texColor.rgb, fractalCol, 0.4);
    
    // Add a subtle "bloom" effect based on the fractal edges
    float bloom = 0.02 / abs(sin(length(uv) - time_f));
    finalRGB += bloom * fractalCol;

    color = vec4(finalRGB, 1.0);
}