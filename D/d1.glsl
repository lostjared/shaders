#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;

void main(void) {
    vec2 uv = tc;

    // Create distortion parameters
    float waveSpeed = 1.1;
    float waveIntensity = 0.26;
    float waveDensity = 8.0;

    // Generate horizontal and vertical distortions
    float horizontalDistortion = sin(uv.y * waveDensity + time_f * waveSpeed) * waveIntensity;
    float verticalDistortion = sin(uv.x * (waveDensity * 0.8) + time_f * waveSpeed * 1.2) * waveIntensity;

    // Apply distortion to texture coordinates
    uv.x += horizontalDistortion;
    uv.y += verticalDistortion;

    // Add radial distortion for more complex effect
    vec2 center = vec2(0.5);
    float distanceFromCenter = length(uv - center);
    float radialDistortion = sin(distanceFromCenter * 15.0 - time_f * 3.0) * 0.015;
    uv += (uv - center) * radialDistortion;

    color = texture(samp, uv);
}