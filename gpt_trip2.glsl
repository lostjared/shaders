#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float lum(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 6; ++i) {
        v += noise(p) * a;
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -0.3333333, 0.6666667, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 0.00001;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(0.0, 0.6666667, 0.3333333)) * 6.0 - 3.0);
    vec3 rgb = clamp(p - 1.0, 0.0, 1.0);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

vec2 warp(vec2 uv) {
    vec2 p = uv * 2.0 - 1.0;
    float r = length(p);
    float a = atan(p.y, p.x);

    float n1 = fbm(uv * 3.2 + vec2(time_f * 0.05, -time_f * 0.04));
    float n2 = fbm(uv * 6.4 + vec2(-time_f * 0.03, time_f * 0.06));

    a += 0.06 * sin(r * 9.0 - time_f * 0.25) + 0.08 * (n1 - 0.5);
    r += 0.018 * sin(a * 7.0 + time_f * 0.18) + 0.015 * (n2 - 0.5);

    p = vec2(cos(a), sin(a)) * r;
    uv = p * 0.5 + 0.5;

    uv += 0.006 * vec2(
        sin(uv.y * 24.0 + time_f * 0.30),
        cos(uv.x * 20.0 - time_f * 0.28)
    );

    return uv;
}

float sobel(vec2 uv, vec2 px) {
    float tl = lum(texture(samp, uv + px * vec2(-1.0, -1.0)).rgb);
    float tc0 = lum(texture(samp, uv + px * vec2( 0.0, -1.0)).rgb);
    float tr = lum(texture(samp, uv + px * vec2( 1.0, -1.0)).rgb);
    float ml = lum(texture(samp, uv + px * vec2(-1.0,  0.0)).rgb);
    float mr = lum(texture(samp, uv + px * vec2( 1.0,  0.0)).rgb);
    float bl = lum(texture(samp, uv + px * vec2(-1.0,  1.0)).rgb);
    float bc = lum(texture(samp, uv + px * vec2( 0.0,  1.0)).rgb);
    float br = lum(texture(samp, uv + px * vec2( 1.0,  1.0)).rgb);

    float gx = -tl - 2.0 * ml - bl + tr + 2.0 * mr + br;
    float gy = -tl - 2.0 * tc0 - tr + bl + 2.0 * bc + br;

    return sqrt(gx * gx + gy * gy);
}

vec3 pastelBase(float t) {
    vec3 a = vec3(0.84, 0.82, 0.86);
    vec3 b = vec3(0.78, 0.92, 0.74);
    vec3 c = vec3(0.46, 0.86, 0.94);
    vec3 d = vec3(0.96, 0.86, 0.38);
    vec3 e = vec3(0.92, 0.28, 0.86);

    if (t < 0.25) return mix(a, b, t / 0.25);
    if (t < 0.50) return mix(b, c, (t - 0.25) / 0.25);
    if (t < 0.75) return mix(c, d, (t - 0.50) / 0.25);
    return mix(d, e, (t - 0.75) / 0.25);
}

void main() {
    vec2 uv = tc;
    vec2 px = 1.0 / iResolution;

    vec2 wuv = warp(uv);

    vec3 src  = texture(samp, wuv).rgb;
    vec3 sx1  = texture(samp, wuv + px * vec2( 1.0,  0.0)).rgb;
    vec3 sx2  = texture(samp, wuv + px * vec2(-1.0,  0.0)).rgb;
    vec3 sy1  = texture(samp, wuv + px * vec2( 0.0,  1.0)).rgb;
    vec3 sy2  = texture(samp, wuv + px * vec2( 0.0, -1.0)).rgb;
    vec3 soft = (src + sx1 + sx2 + sy1 + sy2) / 5.0;

    float e1 = sobel(wuv, px * 1.0);
    float e2 = sobel(wuv, px * 2.0);
    float edge = clamp(e1 * 1.1 + e2 * 0.55, 0.0, 1.0);

    float detail = clamp(length(src - soft) * 4.5, 0.0, 1.0);
    float l = lum(src);

    float n1 = fbm(wuv * 7.0 + edge * 3.0);
    float n2 = fbm(wuv * 18.0 + vec2(time_f * 0.04, -time_f * 0.03));
    float n3 = fbm(wuv.yx * 28.0 + vec2(-time_f * 0.02, time_f * 0.05));

    float field = l * 1.15 + edge * 1.35 + detail * 0.65 + n1 * 0.55;
    float q = floor(field * 9.0) / 9.0;

    vec3 base = pastelBase(clamp(q, 0.0, 1.0));

    vec3 cyan    = vec3(0.05, 0.76, 0.92);
    vec3 aqua    = vec3(0.20, 0.92, 0.72);
    vec3 lime    = vec3(0.55, 0.92, 0.18);
    vec3 yellow  = vec3(0.98, 0.86, 0.12);
    vec3 magenta = vec3(0.88, 0.12, 0.82);
    vec3 violet  = vec3(0.48, 0.28, 0.92);
    vec3 grayLav = vec3(0.80, 0.78, 0.82);

    float flow1 = 0.5 + 0.5 * sin((wuv.x * 12.0 + wuv.y * 16.0) + n1 * 8.0 + field * 7.0);
    float flow2 = 0.5 + 0.5 * sin((wuv.x * 20.0 - wuv.y * 13.0) + n2 * 10.0 + field * 11.0 + 1.4);
    float flow3 = 0.5 + 0.5 * sin((wuv.y * 24.0 + wuv.x * 9.0) + n3 * 12.0 + field * 15.0 + 2.1);

    vec3 river = mix(cyan, aqua, flow1);
    river = mix(river, lime, flow2 * 0.65);
    river = mix(river, yellow, smoothstep(0.58, 0.95, flow3) * 0.45);

    vec3 contour = vec3(0.0);
    contour += magenta * (smoothstep(0.08, 0.25, edge) - smoothstep(0.25, 0.45, edge)) * 0.90;
    contour += violet  * (smoothstep(0.28, 0.50, edge) - smoothstep(0.50, 0.72, edge)) * 0.70;
    contour += cyan    * smoothstep(0.50, 0.95, edge) * 0.45;

    float cells = 0.5 + 0.5 * sin((field + n2 * 0.7) * 42.0);
    float rings = smoothstep(0.72, 0.98, cells) - smoothstep(0.98, 1.0, cells);

    vec3 ringColor = mix(magenta, lime, 0.5 + 0.5 * sin(field * 5.0 + n3 * 3.0));
    ringColor = mix(ringColor, yellow, smoothstep(0.60, 1.00, detail) * 0.35);

    vec3 hsvShift = hsv2rgb(vec3(
        fract(rgb2hsv(src).x + 0.12 * edge + 0.06 * flow2),
        clamp(rgb2hsv(src).y * 1.25 + 0.20 * detail, 0.0, 1.0),
        clamp(rgb2hsv(src).z * 1.05 + 0.08 * edge, 0.0, 1.0)
    ));

    vec3 finalColor = mix(grayLav, base, 0.72);
    finalColor = mix(finalColor, hsvShift, 0.20);
    finalColor = mix(finalColor, river, 0.36 * smoothstep(0.10, 0.80, detail + edge * 0.3));
    finalColor += contour;
    finalColor += ringColor * rings * 0.65;

    float subjectMask = smoothstep(0.06, 0.38, edge + detail * 0.55);
    finalColor = mix(finalColor, mix(river, magenta, 0.18), subjectMask * 0.22);

    float speck = smoothstep(0.78, 0.98, fbm(wuv * 60.0 + edge * 8.0));
    finalColor += magenta * speck * 0.12;
    finalColor -= vec3(0.08, 0.05, 0.10) * speck * 0.10;

    finalColor = mix(finalColor, grayLav, smoothstep(0.72, 1.0, l) * 0.25);
    finalColor = clamp(finalColor, 0.0, 1.0);
    finalColor = pow(finalColor, vec3(0.96));

    color = vec4(finalColor, 1.0);
}