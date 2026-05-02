#version 330 core

out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float uamp;
uniform float amp;

/**
 * A simple swirl-based approach:
 *   1. Shift coords so the center is at (0, 0).
 *   2. Compute radius r and angle θ from the center.
 *   3. Apply a time-varying distortion to θ based on r (and/or noise).
 *   4. Transform back, sample the texture, and output it.
 */

void main(void) {
    // Shift the texture coords so (0.5, 0.5) is the center
    vec2 uv = tc - 0.5;

    // Compute polar coordinates
    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // ---- Tie-dye swirl offset ----
    // You can tweak these parameters to get different effects
    // swirlFreq controls how many "rings" or swirl arms you see
    // swirlAmp  controls how strong the swirl distortion is
    // timeMult  controls how fast the animation evolves
    float swirlFreq = 12.0;       // Number of sinusoidal "bands"
    float swirlAmp = 25.0 * uamp; // Amplitude of the swirl
    float timeMult = 1.5;         // Speed of tie dye motion

    // Create a sinusoidal swirl that depends on both radius and time
    float swirl = sin(r * swirlFreq - time_f * timeMult) * swirlAmp * r;
    // Add the swirl to the angle
    angle += swirl;

    // Convert back to Cartesian coordinates
    uv = r * vec2(cos(angle), sin(angle));

    // Shift coords back to [0,1] range
    uv += 0.5;

    // Sample the texture at our new swirl-distorted coordinates
    vec4 texColor = texture(samp, uv);

    // Output the final color
    color = texColor;
}
