#version 330 core
in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;  // Assuming general amplitude/scale
uniform float uamp; // Assuming intensity/speed multiplier

void main(void) {
    // 1. Center the coordinates and apply aspect ratio correction
    vec2 uv = tc - 0.5;

    // 2. Create the Kaleidoscope Effect
    // We take the absolute value of the coordinates to force 4-way symmetry
    uv = abs(uv);

    // 3. Apply Fractal Layering & Rotation
    // 'uamp' and 'time_f' drive the warping
    float t = time_f * (0.5 + uamp);

    for (int i = 0; i < 3; i++) {
        // Rotate and fold
        float s = sin(t * 0.2);
        float c = cos(t * 0.2);
        uv *= mat2(c, -s, s, c);

        // Dynamic distortion (creating the "crystalline" lines)
        uv = abs(uv * 1.1) - 0.2 * amp;
    }

    // 4. Sample the original texture with warped coordinates
    // We add a subtle oscillation to the sampling to create the "shimmer"
    vec2 warpedTC = uv + 0.5;

    // Mirror clamping logic to keep samples within [0, 1]
    warpedTC = abs(mod(warpedTC - 1.0, 2.0) - 1.0);

    vec4 texColor = texture(samp, warpedTC);

    // 5. Color Grading (Enhancing the Blues/Shadows)
    // We boost the blue channel slightly and add a vignette
    float vignette = smoothstep(0.8, 0.2, length(tc - 0.5));
    texColor.rgb *= vec3(0.8, 0.95, 1.2); // Cool blue tint
    texColor.rgb *= (vignette + 0.2);

    color = texColor;
}