#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

const float PI = 3.14159265359;

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

vec2 polarDistort(vec2 uv) {
    vec2 center = uv - 0.5;
    float angle = atan(center.y, center.x);
    float radius = length(center) * 2.0;

    // Create fractal layers
    float fractal = sin(angle * 5.0 + time_f) * 0.2;
    fractal += sin(angle * 10.0 + time_f * 2.0) * 0.1;
    fractal += sin(angle * 20.0 + time_f * 0.5) * 0.05;

    radius += fractal * 0.3;
    angle += sin(time_f + radius * 5.0) * 0.5;

    vec2 distorted = vec2(cos(angle), sin(angle)) * radius;
    return distorted + 0.5;
}

vec4 fractalColor(vec2 uv) {
    // Create multiple displacement layers
    vec2 uv1 = uv + vec2(sin(time_f * 0.7 + uv.y * 5.0), cos(time_f * 0.6 + uv.x * 5.0)) * 0.1;
    vec2 uv2 = uv + vec2(cos(time_f * 0.5 + uv.y * 10.0), sin(time_f * 0.4 + uv.x * 10.0)) * 0.05;
    vec2 uv3 = uv + vec2(sin(time_f * 0.3 + uv.y * 20.0), cos(time_f * 0.2 + uv.x * 20.0)) * 0.025;

    // Combine texture samples with color modulation
    vec4 col1 = texture(samp, uv1);
    vec4 col2 = texture(samp, uv2);
    vec4 col3 = texture(samp, uv3);

    // Create color shifting effect
    return vec4(col1.r, col2.g, col3.b, 1.0) * (1.0 + sin(time_f * 2.0) * 0.3);
}

void main(void) {
    vec2 uv = tc;

    // Create fractal coordinate system
    uv = polarDistort(uv);

    // Add multiple warping layers
    uv.x += sin(uv.y * 10.0 + time_f * 2.0) * 0.03;
    uv.y += cos(uv.x * 8.0 + time_f * 1.5) * 0.03;

    // Create geometric patterns
    float fractalScale = 5.0;
    uv.x += sin(uv.y * fractalScale + time_f) * 0.1;
    uv.y += cos(uv.x * fractalScale + time_f) * 0.1;

    // Ping pong effect with multiple layers
    float layer1 = pingPong(uv.x + time_f * 0.1, 1.0);
    float layer2 = pingPong(uv.y + time_f * 0.15, 1.0);
    uv = mix(uv, vec2(layer1, layer2), 0.3);

    // Final color with texture preservation
    vec4 finalColor = fractalColor(uv);
    vec4 originalColor = texture(samp, tc);

    // Mix between warped and original texture based on radius
    vec2 centerVec = tc - 0.5;
    float radius = length(centerVec) * 2.0;
    float mixFactor = smoothstep(0.3, 0.7, radius);
    finalColor = mix(finalColor, originalColor, mixFactor * 0.5);

    color = finalColor;
}