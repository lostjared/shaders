#version 330 core
in vec2 tc;
out vec4 color;

uniform float time_f;     // Time value for animation
uniform sampler2D samp;   // Texture sampler
uniform vec2 iResolution; // Screen resolution
uniform vec4 iMouse;      // Mouse position

// Parameters to control the glitch effect
uniform float frequency = 0.5; // Main frequency of the warp
uniform float strength = 1.0;  // Intensity of the warp

void main() {
    vec2 warpedTexCoord = tc;

    // Add noise-based distortion
    float noise = fract(sin(warpedTexCoord.x * frequency + time_f) *
                        4.0);
    noise += fract(sin(warpedTexCoord.y * frequency * 2.0 + time_f) *
                   2.0);
    noise *= strength;

    // Combine with mouse position for interactive warping
    vec2 mousePos = iMouse.xy;
    mousePos.x = sin(mousePos.x * 16.0 + time_f);
    mousePos.y = sin(mousePos.y * 16.0 + time_f);

    warpedTexCoord += noise * mousePos * strength;

    // Apply multiple layers of distortion
    float layer1 = fract(sin(tc.x * 4.0 + time_f) * 2.0);
    float layer2 = fract(sin(tc.y * 4.0 * 2.0 + time_f) * 2.0);
    float layer3 = fract(sin((tc.x + tc.y) * 8.0 + time_f) * 1.0);

    // Combine all layers
    vec2 finalTexCoord = tc + (layer1 + layer2 * mousePos.x + layer3 * mousePos.y) * strength;

    color = mix(texture(samp, sin(finalTexCoord * time_f)), texture(samp, tc), 0.5);
}