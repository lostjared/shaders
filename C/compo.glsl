#version 330 core
in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;

// A simple pseudo-random noise function based on texture coordinates
float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void) {
    // Determine pixel size in texture coordinates
    vec2 pixelSize = vec2(1.0) / iResolution;

    // Simulate chroma separation: offset the red and blue channels slightly.
    // The horizontal displacement is modulated by a sine wave (which gives a time-varying "wobble")
    float displacement = sin(time_f + tc.y * 50.0) * 0.5 * pixelSize.x;
    vec2 offset = vec2(displacement, 0.0);

    // Sample the texture for each channel:
    // - Red channel: sample shifted slightly to the right (or left depending on sine)
    // - Green channel: sample normally for stability
    // - Blue channel: sample shifted in the opposite direction
    float r = texture(samp, tc + offset).r;
    float g = texture(samp, tc).g;
    float b = texture(samp, tc - offset).b;
    vec3 col = vec3(r, g, b);

    // Add a scanline effect by modulating brightness along the vertical axis.
    // The effect multiplies the color by a sinusoid that darkens alternate horizontal lines.
    float scanline = 0.85 + 0.15 * sin(tc.y * iResolution.y * 3.14159);
    col *= scanline;

    // Add some subtle noise to simulate analog signal imperfections.
    float noise = (rand(tc * iResolution + time_f) - 0.5) * 0.1;
    col += noise;

    // Output the final color with full opacity.
    color = vec4(col, 1.0);
}
