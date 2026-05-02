#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
const float PI = 3.1415926535897932384626433832795;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123); }
mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float sdEquilateralTriangle(vec2 p) {
    const float k = 1.7320508075688772;
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0 / k;
    if (p.x + k * p.y > 0.0)
        p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
    p.x -= clamp(p.x, -2.0, 0.0);
    return -length(p) * sign(p.y);
}

float triTile(vec2 p, float scale, float edge) {
    p *= scale;
    vec2 g = floor(p);
    vec2 f = fract(p) - 0.5;
    f *= rot(0.15 * (sin(time_f * 0.6) + sin(dot(g, vec2(1.7, 2.3)))));
    float d = abs(sdEquilateralTriangle(f * 2.0));
    float m = smoothstep(edge, 0.0, d);
    return m;
}

float triFractal(vec2 p) {
    float t = 0.0;
    float s = 3.0;
    float e = 0.18;
    for (int i = 0; i < 4; i++) {
        t = max(t, triTile(p, s, e));
        p *= rot(0.35);
        s *= 1.9;
        e *= 0.8;
    }
    return clamp(t, 0.0, 1.0);
}

void main(void) {
    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float radius = mix(0.8, 1.2, 0.5 + 0.5 * sin(time_f * 1.3)) * 2.0;
    float r = length(uv);
    float glow = smoothstep(radius, radius - 0.25, r);

    vec4 base = texture(samp, tc);

    vec3 pink = vec3(1.0, 0.2, 0.6);
    float pulse = 0.5 + 0.5 * sin(time_f * 3.0);
    float auraAmp = 1.4 * pulse;

    float triMask = triFractal(uv * 1.2 + vec2(0.15 * sin(time_f * 0.7), 0.12 * cos(time_f * 0.55)));
    float lines = pow(triMask, 1.5);
    float flakes = smoothstep(0.6, 1.0, triMask);

    vec3 aura = pink * (0.55 + 0.45 * flakes) * glow * auraAmp;
    vec3 linesGlow = pink * (0.35 + 0.65 * pulse) * lines * glow;

    vec3 col = base.rgb;
    col = mix(col, col + aura, glow * 0.85);
    col += linesGlow * 0.75;
    color = vec4(col, base.a);
}
