#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;

float h1(float n) { return fract(sin(n) * 43758.5453123); }
vec2 h2(float n) { return fract(sin(vec2(n, n + 1.0)) * vec2(43758.5453, 22578.1459)); }
float tri(float x) {
    float f = fract(x);
    return 1.0 - abs(f * 2.0 - 1.0);
}

void main(void) {
    vec2 uv = tc;
    float rate = 0.8;
    float t = time_f * rate;
    float t0 = floor(t);
    float a = fract(t);
    vec2 p0 = vec2(0.1) + h2(t0) * 0.8;
    vec2 p1 = vec2(0.1) + h2(t0 + 1.0) * 0.8;
    float w = a * a * (3.0 - 2.0 * a);
    vec2 m_auto = mix(p0, p1, w);
    vec2 m = (iMouse.z > 0.5 || iMouse.w > 0.5) ? (iMouse.xy / iResolution) : m_auto;

    vec2 d = uv - m;
    float dist = length(d);
    float a1 = clamp(amp, 0.0, 1.0);
    float ua = clamp(uamp, 0.0, 1.0);

    float r0 = mix(0.06, 0.35, a1) * 1.5;
    float pr = tri(time_f * 0.6);
    float r = r0 * mix(0.75, 1.35, pr * (0.3 + 0.7 * ua));

    float s = smoothstep(r, 0.0, dist);
    float k = 0.6 + 0.4 * ua;
    float swirl = (0.8 * ua + 0.2 * a1) * s * (r - dist) * 8.0;
    float ang = atan(d.y, d.x) + swirl;
    vec2 drot = vec2(cos(ang), sin(ang)) * dist;
    float lens = 1.0 - k * s * (1.0 - dist / r);
    vec2 warped = m + drot * lens;

    float wob = sin(time_f * 3.0 + dist * 20.0) * 0.005 * ua * s;
    vec2 n = normalize(drot + vec2(1e-6));
    warped += n * wob;

    vec4 warpedCol = texture(samp, clamp(warped, vec2(0.0), vec2(1.0)));
    color = warpedCol;
}
