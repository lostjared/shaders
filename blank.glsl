#version 330 core

in vec2 tc;
out vec4 color;

// Uniforms
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;

// --------------------------------------------------------
// Random number generator (hash-based, deterministic)
// Generates values in the range [0.0, 1.0]
// --------------------------------------------------------
float rand(vec2 pos) {
    return fract(sin(dot(pos, vec2(12.9898, 78.233))) * 43758.5453);
}

// --------------------------------------------------------
// Draw Julia fractal at a given position with an animated seed
// --------------------------------------------------------
vec4 drawRandomJulia(vec2 uv, vec2 center, vec2 seed) {
    uv = (uv - center) * 3.0;  // Zoom in and center
    vec2 z = uv;
    const int MAX_ITER = 100;
    float brightness = 0.0;

    for (int i = 0; i < MAX_ITER; i++) {
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + seed;
        if (dot(z, z) > 4.0) {
            brightness = float(i) / float(MAX_ITER);
            break;
        }
    }

    vec3 col = vec3(sin(brightness * 6.2831), brightness, 1.0 - brightness);
    return vec4(col, brightness);  // Alpha based on brightness
}

// --------------------------------------------------------
// Main
// --------------------------------------------------------
void main(void) {
    // Start with the base texture
    color = texture(samp, tc);

    // Normalized coordinates (center screen is [0,0])
    vec2 uv = 2.0 * tc - 1.0;

    // Define the cycle duration for changing position/seed
    float cycleDuration = 5.0;
    float cycleTime = mod(time_f, cycleDuration);
    float cycleIndex = floor(time_f / cycleDuration);

    // Random position for the Julia fractal (in screen space [-0.8, 0.8])
    vec2 randomPos = vec2(rand(vec2(cycleIndex, 1.0)), rand(vec2(cycleIndex, 2.0))) * 1.6 - 0.8;

    // Animated seed for the Julia fractal
    vec2 juliaSeed = vec2(sin(time_f * 0.3), cos(time_f * 0.3)) * 0.5;

    // Alpha fade-in/out effect
    float alpha = smoothstep(0.0, 1.0, cycleTime) * smoothstep(cycleDuration, cycleDuration - 1.0, cycleTime);

    // Draw the fractal
    vec4 juliaColor = drawRandomJulia(uv, randomPos, juliaSeed);
    juliaColor.a *= alpha;  // Apply alpha fade

    // Blend with the base texture
    color = mix(color, juliaColor, juliaColor.a);
}
