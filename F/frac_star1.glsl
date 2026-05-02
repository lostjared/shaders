#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;

const float PI = 3.1415926535897932384626433832795;

float hash1(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
vec2 hash2(vec2 p) { return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453); }
float pingPong(float x, float l) {
    float m = mod(x, l * 2.0);
    return m <= l ? m : l * 2.0 - m;
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
vec3 neonPalette(float t) {
    vec3 a = vec3(1.0, 0.15, 0.75), b = vec3(0.10, 0.55, 1.0), c = vec3(0.10, 1.0, 0.45);
    float ph = fract(t * 0.08);
    vec3 k1 = mix(a, b, smoothstep(0.00, 0.33, ph));
    vec3 k2 = mix(b, c, smoothstep(0.33, 0.66, ph));
    vec3 k3 = mix(c, a, smoothstep(0.66, 1.00, ph));
    float A = step(ph, 0.33), B = step(0.33, ph) * step(ph, 0.66), C = step(0.66, ph);
    return normalize(A * k1 + B * k2 + C * k3) * 1.05;
}

vec3 tentBlur3(sampler2D img, vec2 uv, vec2 res) {
    vec2 ts = 1.0 / res;
    vec3 s00 = textureGrad(img, uv + ts * vec2(-1, -1), dFdx(uv), dFdy(uv)).rgb;
    vec3 s10 = textureGrad(img, uv + ts * vec2(0, -1), dFdx(uv), dFdy(uv)).rgb;
    vec3 s20 = textureGrad(img, uv + ts * vec2(1, -1), dFdx(uv), dFdy(uv)).rgb;
    vec3 s01 = textureGrad(img, uv + ts * vec2(-1, 0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s11 = textureGrad(img, uv, dFdx(uv), dFdy(uv)).rgb;
    vec3 s21 = textureGrad(img, uv + ts * vec2(1, 0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s02 = textureGrad(img, uv + ts * vec2(-1, 1), dFdx(uv), dFdy(uv)).rgb;
    vec3 s12 = textureGrad(img, uv + ts * vec2(0, 1), dFdx(uv), dFdy(uv)).rgb;
    vec3 s22 = textureGrad(img, uv + ts * vec2(1, 1), dFdx(uv), dFdy(uv)).rgb;
    return (s00 + 2.0 * s10 + s20 + 2.0 * s01 + 4.0 * s11 + 2.0 * s21 + s02 + 2.0 * s12 + s22) / 16.0;
}
vec3 softTone(vec3 c) {
    c = pow(max(c, 0.0), vec3(0.95));
    float l = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(vec3(l), c, 0.9);
    return clamp(c, 0.0, 1.0);
}

vec2 sitePos(vec2 id, float grid) {
    vec2 j = (hash2(id) * 2.0 - 1.0) * (0.33 + 0.10 * sin(time_f * 0.37 + 6.2831 * hash1(id + 3.71)));
    return (id + 0.5 + j) / grid;
}

float starMetric(vec2 d, float n, float amp) {
    float ang = atan(d.y, d.x);
    float r = length(d);
    float mod = 1.0 + amp * cos(n * ang);
    return r / max(0.001, mod);
}

void main() {
    vec2 res = iResolution;
    float aspect = res.x / res.y;
    vec2 focus = (iMouse.z > 0.5) ? (iMouse.xy / res) : vec2(0.5);

    float t = pingPong(time_f * 0.35, 1.0);
    float zoom = mix(0.7, 2.6, t);
    vec2 uvZ = (tc - focus) * zoom + focus;

    float grid = mix(18.0, 28.0, 0.5 + 0.5 * sin(time_f * 0.11));

    vec2 gtc = uvZ * grid;
    vec2 gid0 = floor(gtc);

    float best1 = 1e9, best2 = 1e9;
    vec2 bestId = vec2(0.0), bestSite = vec2(0.0);
    float bestN = 7.0, bestA = 0.3;

    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 nid = gid0 + vec2(i, j);
            vec2 s = sitePos(nid, grid);
            vec2 d = uvZ - s;
            d.x *= aspect;
            float nPts = floor(7.0 + 5.0 * hash1(nid + 7.7));
            float amp = 0.28 + 0.22 * hash1(nid + 4.2);
            float dist = starMetric(d, nPts, amp);
            if (dist < best1) {
                best2 = best1;
                best1 = dist;
                bestId = nid;
                bestSite = s;
                bestN = nPts;
                bestA = amp;
            } else if (dist < best2) {
                best2 = dist;
            }
        }
    }

    float edge = 0.5 * (best2 - best1);
    float px = 1.0 / min(res.x, res.y);
    float border = 1.0 - smoothstep(px * 0.75, px * 0.75 + fwidth(edge), edge);

    vec2 rel = uvZ - bestSite;
    rel.x *= aspect;

    float rot = 6.2831853 * hash1(bestId + 11.9) + time_f * (0.10 + 0.08 * hash1(bestId + 2.2));
    float cs = cos(rot), sn = sin(rot);
    vec2 rrel = mat2(cs, -sn, sn, cs) * rel;

    vec2 pieceUV = rrel;
    pieceUV.x /= aspect;
    pieceUV += bestSite;

    vec4 texCol = texture(samp, pieceUV);

    float ang = atan(rrel.y, rrel.x);
    float flare = pow(0.5 + 0.5 * cos(bestN * ang + time_f * 0.7 + 6.2831 * hash1(bestId + 3.4)), 3.0);
    vec3 glow = hsv2rgb(vec3(fract(hash1(bestId + 9.3) + time_f * 0.05), 0.85, 1.0));
    vec3 neon = neonPalette(time_f + hash1(bestId + 1.1) * 8.0);
    vec3 tint = mix(neon, glow, 0.45) * (0.55 + 0.45 * flare);
    float rad = length(rrel);
    float vign = smoothstep(0.9, 0.2, rad / (0.55 + 0.05 * sin(time_f * 0.5 + hash1(bestId + 5.5))));
    vec3 pieceCol = mix(texCol.rgb, texCol.rgb * tint, 0.25 * vign);

    vec3 pre = tentBlur3(samp, tc, res);
    vec3 inside = mix(pre, pieceCol, 0.85);

    vec3 borderCol = mix(vec3(0.02, 0.02, 0.03), neonPalette(time_f * 0.5), 0.15);
    vec3 outRGB = mix(inside, sin(borderCol * (time_f * PI)), border);
    outRGB = softTone(outRGB);

    color = vec4(outRGB, texCol.a);
}
