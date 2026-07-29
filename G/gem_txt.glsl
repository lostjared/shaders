#version 330 core
in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;

// Function to generate "fake" scrolling code/text patterns
float text(vec2 p) {
    p.y += time_f * 0.2; // Vertical scroll speed
    vec2 grid = floor(p * vec2(20.0, 40.0));
    float h = fract(sin(dot(grid, vec2(12.9898, 78.233))) * 43758.5453);
    return step(0.5, h) * step(0.3, fract(p.x * 20.0)) * step(0.3, fract(p.y * 40.0));
}

void main(void) {
    // 1. Lens Distortion (Bulge effect)
    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    
    float r = length(uv);
    // Fish-eye math: pushes coordinates outward from the center
    vec2 bulgeUV = tc + (uv * r * 0.2); 

    // 2. Chromatic Aberration (RGB Split)
    // We sample the texture at three slightly different bulges
    float chromaticPower = 0.015 * r;
    float r_ch = texture(samp, bulgeUV + vec2(chromaticPower, 0.0)).r;
    float g_ch = texture(samp, bulgeUV).g;
    float b_ch = texture(samp, bulgeUV - vec2(chromaticPower, 0.0)).b;
    vec3 baseTex = vec3(r_ch, g_ch, b_ch);

    // 3. Digital Overlay (The "Matrix" Complexity)
    // This adds that layer of text/data seen in your image
    float characters = text(bulgeUV * 1.5);
    vec3 textColor = vec3(0.4, 1.0, 0.6) * characters * 0.4;
    
    // 4. Color Grading (The Pink/Gold spectrum)
    // Shifts the background toward the psychedelic tones in the snap
    float hueShift = sin(r * 3.0 - time_f) * 0.5 + 0.5;
    vec3 psychoTone = mix(vec3(0.8, 0.1, 0.5), vec3(0.1, 0.8, 0.9), hueShift);
    
    // 5. Bright Central Flare
    // Replicates the intense white light in the center of the text
    float flare = exp(-r * 3.5) * 2.0;
    vec3 flareColor = vec3(1.0, 1.0, 0.9) * flare;

    // 6. Final Composite
    vec3 result = mix(baseTex, psychoTone, 0.3); // Blend original texture with tones
    result += textColor;                         // Add scrolling text
    result += flareColor;                        // Add the central light
    
    // Subtle vignette to focus the "eye"
    result *= smoothstep(1.5, 0.2, r);

    color = vec4(result, 1.0);
}