#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float alpha;
uniform vec4 iMouse;

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

float smoothNoise(vec2 uv) {
    return sin(uv.x * 12.0 + uv.y * 14.0 + time_f * 0.8) * 0.5 + 0.5;
}

void main(void) {
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 c = (m * iResolution - 0.5 * iResolution) / iResolution.y;

    vec2 uv = (tc * iResolution - 0.5 * iResolution) / iResolution.y - (c - vec2(0.0));
    float radius = length(uv);
    float angle = atan(uv.y, uv.x);

    float mx = (iMouse.z > 0.5) ? (iMouse.x / iResolution.x) : 0.5;
    float my = (iMouse.z > 0.5) ? (iMouse.y / iResolution.y) : 0.5;

    float swirl = sin(time_f * mix(0.25, 0.8, mx)) * mix(1.2, 3.0, my);
    angle += swirl * radius * 1.5;

    float modRadius = pingPong(radius + time_f * mix(0.15, 0.45, mx), 0.8);
    float wave = sin(radius * mix(8.0, 18.0, my) - time_f * mix(2.0, 5.0, mx)) * 0.5 + 0.5;

    float cloudNoise = smoothNoise(uv * 3.0 + vec2(modRadius, angle * 0.5));
    cloudNoise += smoothNoise(uv * 6.0 - vec2(time_f * 0.2, time_f * 0.1));
    cloudNoise = pow(cloudNoise, 1.5);

    float r = sin(angle * 3.0 + modRadius * 8.0 + wave * 2.0) * cloudNoise;
    float g = sin(angle * 5.0 - modRadius * 6.0 + wave * 4.0) * cloudNoise;
    float b = sin(angle * 7.0 + modRadius * 10.0 - wave * 3.0) * cloudNoise;

    vec3 col = vec3(r, g, b) * 0.5 + 0.5;
    vec3 texColor = texture(samp, tc).rgb;
    col = mix(col, texColor, 0.5);

    float t = pingPong(time_f * 1.5, 6.0);
    color = vec4(sin(col * t + 1.5), alpha);
}
