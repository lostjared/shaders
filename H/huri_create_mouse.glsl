#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

float pingPong(float x, float l) {
    float m = mod(x, l * 2.0);
    return m <= l ? m : l * 2.0 - m;
}
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash(i), b = hash(i + vec2(1, 0)), c = hash(i + vec2(0, 1)), d = hash(i + vec2(1, 1));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
vec3 rainbow(float t) {
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

vec2 kaleido(vec2 uv, vec2 c, float seg, vec2 ar) {
    vec2 p = (uv - c) * ar;
    float ang = atan(p.y, p.x);
    float ra = length(p);
    float a = 3.14159265 * 2.0 / seg;
    ang = mod(ang, a);
    ang = abs(ang - a * 0.5);
    p = vec2(cos(ang), sin(ang)) * ra;
    return c + p / ar;
}

vec2 vortex(vec2 uv, vec2 c, float t) {
    vec2 d = uv - c;
    float r = length(d);
    float a = atan(d.y, d.x);
    a += sin(t * 0.9 + r * 12.0) * 0.6 + 0.3 * sin(r * 24.0 - t * 1.7);
    float zoom = 0.15 * sin(t * 0.6 + pow(r, 0.6) * 10.0);
    r = clamp(r * (1.0 - zoom), 0.0, 1.0);
    return c + vec2(cos(a), sin(a)) * r;
}

void main() {
    vec2 ar = vec2(1.0, iResolution.y / iResolution.x);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 uv = tc;
    uv = kaleido(uv, m, 6.0, ar);
    uv = vortex(uv, m, time_f);
    float r1 = 0.002 + 0.002 * sin(time_f * 1.3);
    float r2 = -r1;
    vec2 dir = normalize(uv - m + 1e-6);
    vec2 o1 = dir * r1, o2 = dir * r2;

    float g1 = noise(uv * vec2(iResolution.x / iResolution.y, 1.0) * 5.0 + time_f * 0.7);
    float tw = 0.002 * (g1 - 0.5);

    vec4 cR = texture(samp, uv + o1 + tw);
    vec4 cG = texture(samp, uv + tw);
    vec4 cB = texture(samp, uv + o2 + tw);

    vec3 texRGB = vec3(cR.r, cG.g, cB.b);

    vec2 p = (uv - m) * ar;
    float rad = length(p);
    float ang = atan(p.y, p.x);
    float beat = 0.5 + 0.5 * sin(time_f * 2.1);
    vec3 glow = rainbow(ang / (6.28318) + time_f * 0.15) * smoothstep(0.9, 0.0, rad) * beat;

    float strobe = smoothstep(0.0, 1.0, 0.5 + 0.5 * sin(time_f * 10.0 + rad * 40.0));
    vec3 neon = mix(texRGB, texRGB * rainbow(time_f * 0.1 + rad * 2.0), 0.35 + 0.25 * strobe);
    neon += glow * 0.7;

    float vign = 1.0 - smoothstep(0.7, 1.05, rad);
    color = vec4(neon * vign, 1.0);
}
