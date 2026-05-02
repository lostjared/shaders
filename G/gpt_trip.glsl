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
    float n1 = noise(uv * 5.0 + vec2(time_f * 0.08, -time_f * 0.06));
    float n2 = noise(uv * 9.0 + vec2(-time_f * 0.05, time_f * 0.07));
    a += 0.04 * sin(r * 8.0 - time_f * 0.5) + 0.03 * (n1 - 0.5);
    r += 0.012 * sin(a * 6.0 + time_f * 0.4) + 0.01 * (n2 - 0.5);
    p = vec2(cos(a), sin(a)) * r;
    uv = p * 0.5 + 0.5;
    uv += 0.004 * vec2(
                      sin(uv.y * 22.0 + time_f * 0.7),
                      cos(uv.x * 18.0 - time_f * 0.6));
    return uv;
}

float edgeSobel(vec2 uv, vec2 px) {
    float tl = lum(texture(samp, uv + px * vec2(-1.0, -1.0)).rgb);
    float tc0 = lum(texture(samp, uv + px * vec2(0.0, -1.0)).rgb);
    float tr = lum(texture(samp, uv + px * vec2(1.0, -1.0)).rgb);
    float ml = lum(texture(samp, uv + px * vec2(-1.0, 0.0)).rgb);
    float mr = lum(texture(samp, uv + px * vec2(1.0, 0.0)).rgb);
    float bl = lum(texture(samp, uv + px * vec2(-1.0, 1.0)).rgb);
    float bc = lum(texture(samp, uv + px * vec2(0.0, 1.0)).rgb);
    float br = lum(texture(samp, uv + px * vec2(1.0, 1.0)).rgb);

    float gx = -tl - 2.0 * ml - bl + tr + 2.0 * mr + br;
    float gy = -tl - 2.0 * tc0 - tr + bl + 2.0 * bc + br;

    return sqrt(gx * gx + gy * gy);
}

void main() {
    vec2 uv = tc;
    vec2 px = 1.0 / iResolution;

    vec2 wuv = warp(uv);

    vec3 src = texture(samp, wuv).rgb;
    vec3 s1 = texture(samp, wuv + px * vec2(1.0, 0.0)).rgb;
    vec3 s2 = texture(samp, wuv + px * vec2(-1.0, 0.0)).rgb;
    vec3 s3 = texture(samp, wuv + px * vec2(0.0, 1.0)).rgb;
    vec3 s4 = texture(samp, wuv + px * vec2(0.0, -1.0)).rgb;

    vec3 soft = (src + s1 + s2 + s3 + s4) / 5.0;

    float edge = edgeSobel(wuv, px);
    edge = clamp(edge * 1.6, 0.0, 1.0);

    float detail = length(src - soft);
    detail = clamp(detail * 3.0, 0.0, 1.0);

    vec3 hsv = rgb2hsv(src);
    hsv.x = fract(hsv.x + 0.08 * sin(lum(src) * 8.0 + time_f * 0.25) + 0.12 * edge);
    hsv.y = clamp(hsv.y * 1.4 + 0.2 * detail + 0.2 * edge, 0.0, 1.0);
    hsv.z = clamp(hsv.z * 1.05 + 0.12 * detail, 0.0, 1.0);

    vec3 neonBase = hsv2rgb(hsv);

    vec3 edgeTint1 = vec3(1.0, 0.1, 0.9);
    vec3 edgeTint2 = vec3(0.1, 1.0, 0.5);
    vec3 edgeTint3 = vec3(0.2, 0.6, 1.0);

    vec3 contour = vec3(0.0);
    contour += edgeTint1 * smoothstep(0.10, 0.35, edge);
    contour += edgeTint2 * smoothstep(0.25, 0.60, edge);
    contour += edgeTint3 * smoothstep(0.45, 0.90, edge);

    float rings = 0.5 + 0.5 * sin((lum(src) + detail * 0.7) * 20.0 + time_f * 0.2);
    vec3 ringTint = mix(vec3(0.8, 0.1, 1.0), vec3(0.1, 0.9, 1.0), rings);

    vec3 finalColor = mix(src, neonBase, 0.45);
    finalColor += contour * 0.35;
    finalColor += ringTint * detail * 0.12;

    finalColor = mix(finalColor, src, smoothstep(0.75, 1.0, lum(src)) * 0.45);

    finalColor = clamp(finalColor, 0.0, 1.0);
    finalColor = pow(finalColor, vec3(0.95));

    color = vec4(finalColor, 1.0);
}