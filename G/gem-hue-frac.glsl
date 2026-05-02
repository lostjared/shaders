#version 330

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

// Helper to create the back-and-forth motion
float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

// Optimized Hue adjustment for smooth transitions
vec3 hueShift(vec3 col, float hue) {
    const vec3 k = vec3(0.57735, 0.57735, 0.57735);
    float cosAngle = cos(hue);
    return col * cosAngle + cross(k, col) * sin(hue) + k * dot(k, col) * (1.0 - cosAngle);
}

void main() {
    // 1. Center and aspect-correct UVs
    vec2 uv = (tc - 0.5) * iResolution / min(iResolution.x, iResolution.y);
    vec2 uv0 = uv; // Store original UV for global reference

    vec3 finalCol = vec3(0.0);
    float t = time_f * 0.2; // Slow down time for a trippier effect

    // 2. The Fractal Loop
    // Iterating and folding space creates the fractal "repetition"
    for (float i = 0.0; i < 4.0; i++) {
        // Fold space (Kaleidoscopic effect)
        uv = fract(uv * 1.5) - 0.5;

        // Calculate distance with a pulsing variance
        float d = length(uv) * exp(-length(uv0));

        // Create the "neon" edge/ring effect based on time
        vec3 col = vec3(0.5, 0.8, 0.9); // Base tint
        d = sin(d * 8.0 + t) / 8.0;
        d = abs(d);
        d = pow(0.01 / d, 1.2); // Intensify the edges into "glow"

        // Shift hue per iteration for color depth
        finalCol += col * d;
    }

    // 3. Texture Sampling with Distortion
    // We use the fractal math to displace the texture lookup
    float distortion = length(finalCol.rg) * 0.05;
    vec4 sampledColor = texture(samp, tc + distortion);

    // 4. Final Color Correction
    float shiftAmt = pingPong(time_f, 5.0);
    vec3 shiftedColor = hueShift(sampledColor.rgb + (finalCol * 0.5), shiftAmt);

    color = vec4(shiftedColor, 1.0);
}