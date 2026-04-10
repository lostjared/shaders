#version 330 core

// Input texture coordinate from vertex shader
in vec2 tc;

// Final output color
out vec4 color;

// Uniforms for time, texture sampler, screen resolution, and mouse (if needed)
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;

// A helper function to generate pseudo-random values based on a 2D input.
float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void) {
    // Start with the original texture coordinates.
    vec2 uv = tc;
    
    // ==========================================================
    // 1. Roll Effect: Scroll the texture vertically over time.
    // ==========================================================
    float rollSpeed = 0.2;  // Adjust roll speed as desired.
    // The mod wraps the y coordinate to stay within [0,1]
    uv.y = mod(uv.y + time_f * rollSpeed, 1.0);
    
    // ==========================================================
    // 2. Bending (Warp) Effect: Sine-wave distortion on x.
    // ==========================================================
    float bendAmplitude = 0.02;  // How strong the bending is.
    float bendFrequency = 10.0;  // Number of waves along the y axis.
    // The sine function creates a wave; multiplying time_f adds an evolving distortion.
    uv.x += sin(uv.y * 3.1415 * bendFrequency + time_f * 2.0) * bendAmplitude;
    
    // ==========================================================
    // 3. VHS Skipping Effect: Simulate bad tracking with jitter.
    // ==========================================================
    // Generate a random value that changes over time and along y.
    float jitterChance = rand(vec2(time_f, uv.y));
    // If the random value is high enough (here, > 0.95) then trigger a skip.
    if(jitterChance > 0.95) {
        // Compute a random horizontal jump offset.
        float jitterAmount = (rand(vec2(time_f * 2.0, uv.y * 3.0)) - 0.5) * 0.1;
        uv.x += jitterAmount;
    }
    
    // ==========================================================
    // 4. Optional: Chromatic Aberration for a VHS-style color offset.
    // ==========================================================
    float chromaShift = 0.005;
    float r = texture(samp, uv + vec2(chromaShift, 0.0)).r;
    float g = texture(samp, uv).g;
    float b = texture(samp, uv - vec2(chromaShift, 0.0)).b;
    
    // Output the final color.
    color = vec4(r, g, b, 1.0);
}
