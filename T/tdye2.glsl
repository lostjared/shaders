#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float uamp;
uniform float amp;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    float a = hash(i), b = hash(i + vec2(1, 0)), c = hash(i + vec2(0, 1)), d = hash(i + vec2(1, 1));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    mat2 m = mat2(1.6, 1.2, -1.2, 1.6);
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = m * p + 1.7;
        a *= 0.5;
    }
    return v;
}
float pingPong(float x, float L) {
    float m = mod(x, 2.0 * L);
    return m <= L ? m : (2.0 * L - m);
}
vec3 grad4(vec3 c0, vec3 c1, vec3 c2, vec3 c3, float x) {
    x = clamp(x, 0.0, 1.0);
    if (x < 0.25)
        return mix(c0, c1, x / 0.25);
    else if (x < 0.50)
        return mix(c1, c2, (x - 0.25) / 0.25);
    else if (x < 0.75)
        return mix(c2, c3, (x - 0.50) / 0.25);
    else
        return mix(c3, c0, (x - 0.75) / 0.25);
}
vec3 rgb2yc(vec3 c) {
    float y = dot(c, vec3(0.299, 0.587, 0.114));
    float cb = (c.b - y) * 0.565;
    float cr = (c.r - y) * 0.713;
    return vec3(y, cb, cr);
}
vec3 yc2rgb(vec3 ycc) {
    float y = ycc.x, cb = ycc.y, cr = ycc.z;
    return vec3(y + 1.403 * cr, y - 0.344 * cb - 0.714 * cr, y + 1.770 * cb);
}

void main() {
    vec2 uv = tc;
    vec2 res = iResolution;
    float t = time_f;

    vec2 p = uv - 0.5;
    p.x *= res.x / max(res.y, 1.0);

    float speed = 0.25 + 0.45 * uamp + 0.25 * amp;
    float zPhase = pingPong(t * speed, 1.0);
    float minPow = -1.5;
    float maxPow = 12.0;
    float scale = exp2(mix(minPow, maxPow, zPhase));

    float rot = 0.25 * t + 0.12 * sin(t * 0.29) + 0.08 * sin(t * 0.47);
    float cs = cos(rot), sn = sin(rot);
    mat2 R = mat2(cs, -sn, sn, cs);

    vec2 warp = (vec2(fbm(p * 2.3 + vec2(0.0, t * 0.18)), fbm(p * 2.0 + vec2(t * 0.21, 0.0))) - 0.5) * 0.55;

    vec2 zoomPos = (R * p) * (3.0 * scale) + warp;
    float ring = length(zoomPos);
    float angle = atan(zoomPos.y, zoomPos.x);

    float drift = 0.23 * sin(t * 0.23) + 0.18 * sin(t * 0.41) + 0.12 * sin(t * 0.59);
    float bands = ring * (8.0 + 12.0 * amp) + 0.9 * sin(angle * 3.0 + t * 0.7) + fbm(zoomPos * 1.7 + t * 0.2) * 1.8;
    float gCoord = fract(bands * 0.25 + drift);

    vec3 G0 = vec3(1.00, 0.20, 0.30);
    vec3 G1 = vec3(1.00, 0.90, 0.20);
    vec3 G2 = vec3(0.20, 0.95, 0.35);
    vec3 G3 = vec3(0.25, 0.45, 1.00);
    vec3 dyeRGB = grad4(G0, G1, G2, G3, gCoord);
    dyeRGB = pow(dyeRGB, vec3(0.9)) * 1.25;

    vec2 reTex = (R * p) * (0.9 * scale) + warp * 0.15;
    reTex.x /= (res.x / max(res.y, 1.0));
    vec2 sampleUV = fract(reTex + 0.5);

    vec3 base = texture(samp, sampleUV).rgb;
    float Y = dot(base, vec3(0.299, 0.587, 0.114));
    vec3 dyeYC = rgb2yc(dyeRGB);
    float yBlend = mix(0.15, 0.45, clamp(uamp, 0.0, 1.0));
    float Ymix = mix(Y, dot(dyeRGB, vec3(0.299, 0.587, 0.114)), yBlend);
    vec3 outYC = vec3(Ymix, dyeYC.yz);
    vec3 dyed = yc2rgb(outYC);

    float caAmt = 0.0016 + 0.003 * uamp;
    vec3 chroma;
    chroma.r = texture(samp, fract(sampleUV + vec2(caAmt, 0.0))).r;
    chroma.g = dyed.g;
    chroma.b = texture(samp, fract(sampleUV - vec2(caAmt, 0.0))).b;
    dyed = mix(dyed, chroma, 0.18);

    float vign = smoothstep(1.15, 0.35, length(p));
    dyed *= mix(1.0, 0.93, vign);

    color = vec4(clamp(dyed, 0.0, 1.0), 1.0);
}
