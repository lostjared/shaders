#version 330 core
in vec2 tc;
out vec4 color;

uniform sampler2D samp; // Assuming uniform sampler2D for texture sampling
uniform vec2 iResolution;
uniform float time_f; // Time in seconds, smoothly varying over frames
uniform float amp;    // Amplitude of the glitch effect
uniform float uamp;   // Probability or frequency of the glitch effect
uniform float alpha_r;

// Simple hash function to introduce randomness
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 getDatamosh(vec2 uv) {
    // Define block size and calculate the UV coordinates for the current block
    float blockSize = (alpha_r * 2.0) * 16.0;
    vec2 blockUV = floor(uv * iResolution / blockSize) * (blockSize / iResolution);

    // Sample the color of the block
    vec4 blockColor = texture(samp, blockUV);
    float luma = dot(blockColor.rgb, vec3(0.299, 0.587, 0.114));

    // Create a motion vector based on luma and time
    vec2 motion = vec2(sin(luma * 20.0 + time_f) * amp, cos(luma * 20.0 + time_f) * amp);

    // Trigger the glitch effect based on uamp
    float moshTrigger = hash(blockUV + floor(time_f * 8.0));

    vec2 finalUV = uv;
    if (moshTrigger < uamp) {
        // Apply motion blur to simulate a moving artifact
        finalUV += motion * sin(time_f);
    }

    // Sample the texture with potential distorted UVs and combine colors
    vec3 col;
    col.r = texture(samp, finalUV).r;
    col.g = texture(samp, finalUV + (motion * amp * 0.2)).g;
    col.b = texture(samp, finalUV + (motion * amp * 0.4)).b;

    // Return the color with full opacity for now, modify alpha as needed
    return vec4(col, 1.0);
}

void main(void) {
    vec2 uv = tc;

    // Apply the datamosh effect to get the final color
    vec4 finalColor = getDatamosh(uv);

    // Add slight quantization to mimic video compression artifacts
    finalColor.rgb = floor(finalColor.rgb * 16.0) / 16.0;

    // Output the final color with alpha (if applicable)
    color = finalColor;
}
