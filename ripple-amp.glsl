#version 330 core
in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

void main(void) {
    float yPos = gl_FragCoord.y / iResolution.y;
    float xPos = gl_FragCoord.x / iResolution.x;

    // Random phase per scanline
    float rndY = hash(floor(yPos * 200.0));
    float rndX = hash(floor(xPos * 150.0));

    // Faster wave motion
    float waveY = sin(yPos * (10.0 + rndY * 5.0) + time_f * (4.0 + rndX * 2.0));
    float waveX = cos(xPos * (8.0 + rndX * 4.0) + time_f * (3.0 + rndY * 2.0));

    // Slightly higher amplitude, with randomized modulation
    float amplitude = 0.025 + 0.015 * hash(floor(time_f * 0.5));
    vec2 offset = vec2(waveX, waveY) * amplitude;

    vec2 coord = clamp(tc + offset, 0.001, 0.999);
    color = texture(samp, coord);
}
