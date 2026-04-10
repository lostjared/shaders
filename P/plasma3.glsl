#version 330 core

in vec2 tc;
out vec4 color;
uniform float time_f;
uniform vec2 iResolution;
uniform sampler2D samp;

float PI = 3.1415926535897932384626433832795;

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}


void main() {
    vec2 ar = vec2(iResolution.x / iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * ar;

    float r = max(length(p), 1e-4);
    float a = atan(p.y, p.x);

    float t = time_f;
    float pulse = 0.5 + 0.5 * sin(t * 2.0);
    float zoomSpeed = 0.35 + 0.15 * sin(t * 0.7);
    float swirl = 0.05 * sin(6.0 * a + t * 2.0 + r * 10.0);
    float wobble = 0.10 * sin(a * 8.0 + t * 1.5);

    float lr = log(r);
    lr += zoomSpeed * t;
    lr = fract(lr * (1.0 + 0.25 * pulse));
    lr = (lr - 0.5) * 2.0 + wobble;

    a += sin(swirl * (pingPong(time_f, 10.0) * PI));

    float nr = exp(lr);
    vec2 q = vec2(cos(a), sin(a)) * nr;
    vec2 baseUV = q / ar + 0.5;

    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= ar.x;

    float plasma = 0.0;
    plasma += sin((uv.x + t) * 5.0);
    plasma += sin((uv.y + t) * 5.0);
    plasma += sin((uv.x + uv.y + t) * 5.0);
    plasma += cos(length(uv + t) * 10.0);
    plasma *= 0.25;

    vec3 baseColor;
    baseColor.r = cos(plasma * PI + t * 0.2) * 0.5 + 0.5;
    baseColor.g = sin(plasma * PI + t * 0.2) * 0.5 + 0.5;
    baseColor.b = sin(plasma * PI + t * 0.4) * 0.5 + 0.5;

    vec2 dir = normalize(q + 1e-5);
    float disp = 0.002 + 0.01 * pulse;

    float rC = texture(samp, baseUV + dir * disp).r;
    float gC = texture(samp, baseUV).g;
    float bC = texture(samp, baseUV - dir * disp).b;

    vec3 prismColor = vec3(rC, gC, bC);

    float morph = 0.5 + 0.5 * sin(t * 1.1);
    vec3 mixed = mix(baseColor, prismColor, 0.6 + 0.4 * morph);

    float breathe = 0.5 + 0.5 * sin(t * 3.0 + length(q) * 12.0);
    mixed *= 0.9 + 0.2 * sin(breathe * pingPong(time_f, 10.0));

    color = vec4(mixed, 1.0);
}
