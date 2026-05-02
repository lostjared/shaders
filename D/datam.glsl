#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f; // Using time_f as requested
uniform float amp;    // Displacement distance
uniform float uamp;   // Glitch probability/frequency

// Standard hash function for block randomness
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec3 getDatamosh(vec2 uv) {
    // 1. Define Macroblocks (typical of MPEG artifacts)
    float blockSize = 16.0;
    vec2 blockUV = floor(uv * iResolution / blockSize) * blockSize / iResolution;

    // 2. Derive "Motion" from the image itself
    // We sample the block color to determine which way the pixels "bleed"
    vec3 blockColor = texture(samp, blockUV).rgb;
    float luma = dot(blockColor, vec3(0.299, 0.587, 0.114));

    // Create a vector based on luma and time
    vec2 motion;
    motion.x = sin(luma * 20.0 + time_f) * 0.05;
    motion.y = cos(luma * 15.0 + time_f) * 0.05;

    // 3. Datamosh Trigger
    // uamp scales the probability that a block will 'break'
    float moshTrigger = hash(blockUV + floor(time_f * 8.0));

    vec2 finalUV = uv;
    if (moshTrigger < uamp * 0.5) {
        // Drag the UV coordinates based on the motion vector and amp
        finalUV -= motion * amp;
    }

    // 4. Chroma Subsampling Artifacts
    // Real datamosh often has misaligned color planes
    vec3 col;
    col.r = texture(samp, finalUV).r;
    col.g = texture(samp, finalUV + (motion * amp * 0.2)).g;
    col.b = texture(samp, finalUV + (motion * amp * 0.4)).b;

    return col;
}

void main(void) {
    vec2 uv = tc;

    vec3 finalColor = getDatamosh(uv);

    // Slight quantization to mimic 8-bit video compression
    finalColor = floor(finalColor * 16.0) / 16.0;

    color = vec4(finalColor, texture(samp, uv).a);
}