#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float PI() { return 3.14159265358979323846; }

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

vec3 triadMask(vec2 uv) {
    float px = floor(uv.x * iResolution.x);
    float m = mod(px, 3.0);
    vec3 a = vec3(1.10, 0.88, 0.88);
    vec3 b = vec3(0.88, 1.10, 0.88);
    vec3 c = vec3(0.88, 0.88, 1.10);
    return mix(mix(c, b, step(1.0, m)), a, step(2.0, m));
}

float scanline(vec2 uv) {
    float y = uv.y * iResolution.y;
    return 0.84 + 0.16 * sin(PI() * y);
}

vec3 halation(vec2 uv) {
    vec2 px = 1.0 / iResolution;
    vec3 s = vec3(0.0);
    s += texture(samp, uv + vec2(px.x, 0.0)).rgb * 0.10;
    s += texture(samp, uv + vec2(-px.x, 0.0)).rgb * 0.10;
    s += texture(samp, uv + vec2(0.0, px.y)).rgb * 0.10;
    s += texture(samp, uv + vec2(0.0, -px.y)).rgb * 0.10;
    s += texture(samp, uv + vec2(px.x, px.y)).rgb * 0.06;
    s += texture(samp, uv + vec2(-px.x, px.y)).rgb * 0.06;
    s += texture(samp, uv + vec2(px.x, -px.y)).rgb * 0.06;
    s += texture(samp, uv + vec2(-px.x, -px.y)).rgb * 0.06;
    return s;
}

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

vec3 rgb2yiq(vec3 c) {
    float Y = dot(c, vec3(0.299, 0.587, 0.114));
    float I = dot(c, vec3(0.596, -0.274, -0.322));
    float Q = dot(c, vec3(0.211, -0.523, 0.312));
    return vec3(Y, I, Q);
}

vec3 yiq2rgb(vec3 yIQ) {
    float Y = yIQ.x, I = yIQ.y, Q = yIQ.z;
    return mat3(1.0, 1.0, 1.0,
                0.956, -0.272, -1.106,
                0.621, -0.647, 1.703) *
           vec3(Y, I, Q);
}

vec3 compositeEffect(vec2 uv) {
    float offset = 0.01;
    vec3 col;
    col.r = texture(samp, uv + vec2(offset, 0.0)).r;
    col.g = texture(samp, uv).g;
    col.b = texture(samp, uv - vec2(offset, 0.0)).b;
    float noise = fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453);
    col += noise * 0.05;
    float scanline = sin(uv.y * iResolution.y * 1.5) * 0.1;
    col -= scanline;
    float bleed = sin(uv.y * iResolution.y * 0.2 + time_f * 5.0) * 0.005;
    col.r += bleed * 0.002;
    col.b -= bleed * 0.002;
    return col;
}

void main() {
    vec2 uv = tc;
    vec2 px = 1.0 / iResolution;

    float hs = (sin(time_f * 120.0) + sin((uv.y + time_f * 0.61) * 87.0)) * 0.0006;
    uv.x += hs;

    float jitter = (hash(vec2(floor(gl_FragCoord.y * 0.5), time_f)) * 2.0 - 1.0) * 0.00045;
    uv.x += jitter;

    vec3 s0 = texture(samp, uv).rgb;
    vec3 sL1 = texture(samp, uv - vec2(px.x, 0)).rgb;
    vec3 sR1 = texture(samp, uv + vec2(px.x, 0)).rgb;
    vec3 sL2 = texture(samp, uv - vec2(px.x * 2.0, 0)).rgb;
    vec3 sR2 = texture(samp, uv + vec2(px.x * 2.0, 0)).rgb;

    vec3 y0 = rgb2yiq(s0);
    vec3 yL1 = rgb2yiq(sL1);
    vec3 yR1 = rgb2yiq(sR1);
    vec3 yL2 = rgb2yiq(sL2);
    vec3 yR2 = rgb2yiq(sR2);

    float Y = 0.40 * y0.x + 0.24 * (yL1.x + yR1.x) + 0.06 * (yL2.x + yR2.x);
    float Ih = 0.40 * y0.y + 0.24 * (yL1.y + yR1.y) + 0.06 * (yL2.y + yR2.y);
    float Qh = 0.36 * y0.z + 0.12 * (yL1.z + yR1.z) + 0.02 * (yL2.z + yR2.z);

    float sub = 227.5;
    float line = floor(gl_FragCoord.y);
    float phase = 6.2831853 * (gl_FragCoord.x * sub / iResolution.x + mod(line, 2.0) * 0.5 + time_f * 0.03);
    mat2 R = mat2(cos(phase), -sin(phase), sin(phase), cos(phase));
    vec2 IQm = R * vec2(Ih, Qh);

    float Yhp = Y - 0.5 * (yL1.x + yR1.x);

    Yhp = sin(Yhp * PI());

    vec2 cc = vec2(cos(phase), sin(phase)) * Yhp * 0.18;
    IQm += cc;

    vec2 IQd = R * vec2(
                       0.50 * y0.y + 0.30 * yL1.y + 0.20 * yR1.y,
                       0.55 * y0.z + 0.28 * yL1.z + 0.17 * yR1.z);

    float tHop = 0.5;
    vec2 IQdelay = vec2(
        texture(samp, uv - vec2(px.x * tHop, 0)).rg);
    vec3 yDelay = rgb2yiq(texture(samp, uv - vec2(px.x * tHop, 0)).rgb);
    IQd = mix(IQd, vec2(yDelay.y, yDelay.z), 0.35);

    vec2 IQ = mix(IQm, IQd, 0.5);
    IQ *= 0.92;

    vec3 ntsc = yiq2rgb(vec3(Y, IQ.x, IQ.y));

    vec3 bleedH = (texture(samp, uv + vec2(px.x * 1.2, 0)).rgb + texture(samp, uv - vec2(px.x * 1.2, 0)).rgb) * 0.25;
    vec3 ghost = texture(samp, uv - vec2(px.x * 2.2, 0)).rgb * 0.10;
    vec3 base = mix(ntsc, ntsc * 0.6 + bleedH * 0.4 + ghost, 0.45);

    float sl = scanline(uv);
    vec3 tri = triadMask(uv);
    float grille = 0.95 + 0.05 * sin(uv.x * iResolution.x * PI() * 0.5);
    float flick = 0.992 + 0.008 * sin(time_f * 360.0);

    vec3 bloom = halation(uv) * 0.28;
    float n = (hash(gl_FragCoord.xy + time_f * vec2(173.1, 91.7)) * 2.0 - 1.0) * 0.018;
    base += n;

    vec3 linear = pow(clamp(base, 0.0, 1.0), vec3(2.2)) + pow(bloom, vec3(2.2)) * 0.55;
    vec3 shaped = linear * tri * sl * grille * flick;
    vec3 outc = pow(shaped, vec3(1.0 / 2.2));

    float black = 0.02;
    float white = 1.05;
    outc = clamp((outc - black) / (white - black), 0.0, 1.0);
    color = mix(vec4(compositeEffect(uv), 1.0), vec4(outc, 1.0), 0.5);
}
