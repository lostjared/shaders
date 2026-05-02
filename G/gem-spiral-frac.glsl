#version 330

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

// Helper to create the neon color spectrum
vec3 neon(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

// Rotation matrix for the fractal folding
mat2 rotate2d(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution.xy) : vec2(0.5);
    vec2 uv = tc;

    // --- Original Distortion Logic ---
    float dist = distance(uv, m);
    float falloff = smoothstep(0.5, 0.0, dist);
    float distortionStrength = 0.03 * falloff;
    float distortionFrequency = 20.0;

    float d1 = sin((uv.y + dist * 5.0) * distortionFrequency + time_f) * distortionStrength;
    float d2 = cos((uv.x + uv.y + dist * 5.0) * distortionFrequency + time_f) * distortionStrength;
    vec2 distortedUV = uv + vec2(d1, d2);

    // --- Spiral Fractal Logic ---
    // Shift coordinates to be relative to the mouse (or center)
    vec2 p = (distortedUV - m);
    p.x *= aspect; // Correct aspect ratio for a circular look

    float p_dist = length(p);
    float p_angle = atan(p.y, p.x);

    // Fractal Loop: Iteratively fold and rotate the space
    float fractalLayer = 0.0;
    vec2 iterP = p;
    float zoom = 1.5 + 0.5 * sin(time_f * 0.5); // Ping-ponging zoom

    for (int i = 0; i < 5; i++) {
        iterP = abs(iterP) * zoom - 0.8;            // Mirror fold and scale
        iterP *= rotate2d(time_f * 0.2 + float(i)); // Rotate each layer
        fractalLayer += exp(-length(iterP) * 2.0);  // Accumulate "light"
    }

    // Spiral calculation
    // angle + log(radius) creates the logarithmic spiral shape
    float spiral = p_angle + log(p_dist + 0.001) * 2.0 - time_f * 3.0;
    float spiralPattern = smoothstep(0.1, 0.9, sin(spiral * 5.0));

    // Combine fractal light with neon colors
    vec3 fractalCol = neon(p_dist - time_f * 0.5 + fractalLayer * 0.1);
    fractalCol *= fractalLayer * spiralPattern;

    // --- Final Composition ---
    vec4 tex = texture(samp, distortedUV);

    // Mix the base texture with the glowing fractal aura
    // The fractal appears stronger where the distortion is (falloff)
    vec3 finalRGB = mix(tex.rgb, fractalCol, falloff * 0.7);

    // Add a little extra "strobe" punch to the highlights
    finalRGB += fractalCol * (0.5 + 0.5 * sin(time_f * 10.0)) * 0.2;

    color = vec4(finalRGB, 1.0);
}