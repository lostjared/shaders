#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect) {
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

vec2 reflectUV(vec2 uv, float segments, vec2 c, float aspect) {
    vec2 p = uv - c;
    p.x *= aspect;
    float ang = atan(p.y, p.x);
    float rad = length(p);
    float stepA = 6.28318530718 / segments;
    ang = mod(ang, stepA);
    ang = abs(ang - stepA * 0.5);
    vec2 r = vec2(cos(ang), sin(ang)) * rad;
    r.x /= aspect;
    return r + c;
}

vec2 fractalFold(vec2 uv, float zoom, float t, vec2 c, float aspect) {
    vec2 p = uv;
    for (int i = 0; i < 6; i++) {
        p = abs((p - c) * (zoom + 0.15 * sin(t * 0.35 + float(i)))) - 0.5 + c;
        p = rotateUV(p, t * 0.12 + float(i) * 0.07, c, aspect);
    }
    return p;
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 movingGradient(vec2 uv, vec2 c, float t, float aspect) {
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (uv - c) * ar;
    vec2 d = normalize(vec2(cos(t * 0.27), sin(t * 0.31)));
    float s = dot(p, d);
    float band = 0.5 + 0.5 * sin(s * 6.28318530718 * 0.35 + t * 0.9);
    float h = fract(s * 0.22 + t * 0.07 + 0.15 * sin(t * 0.33));
    float S = 0.75 + 0.25 * sin(t * 0.21 + s * 2.0);
    float V = 0.75 + 0.25 * band;
    vec3 base = hsv2rgb(vec3(h, S, V));
    float edge = smoothstep(0.2, 0.8, band);
    return mix(base * 0.6, base, edge);
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 uv = tc;
    vec4 originalTexture = texture(samp, tc);

    float seg = 6.0 + 2.0 * sin(time_f * 0.33);
    vec2 kUV = reflectUV(uv, seg, m, aspect);
    float foldZoom = 1.45 + 0.55 * sin(time_f * 0.42);
    kUV = fractalFold(kUV, foldZoom, time_f, m, aspect);
    kUV = rotateUV(kUV, time_f * 0.23, m, aspect);

    vec2 p = (kUV - m) * ar;
    float base = 1.82 + 0.18 * sin(time_f * 0.2);
    float period = log(base);
    float tz = time_f * 0.65;
    float r = length(p) + 1e-6;
    float ang = atan(p.y, p.x) + tz * 0.35 + 0.35 * sin(r * 9.0 + time_f * 0.8);
    float k = fract((log(r) - tz) / period);
    float rw = exp(k * period);
    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw;

    vec2 u0 = fract(pwrap / ar + m);
    vec2 u1 = fract((pwrap * 1.045) / ar + m);
    vec2 u2 = fract((pwrap * 0.955) / ar + m);

    vec2 dir = normalize(pwrap + 1e-6);
    vec2 off = dir * (0.0015 + 0.001 * sin(time_f * 1.3)) * vec2(1.0, 1.0 / aspect);

    float hue = fract(ang * 0.15 + time_f * 0.08 + k * 0.5);
    float sat = 0.8 - 0.2 * cos(time_f * 0.7 + r * 6.0);
    float val = 0.8 + 0.2 * sin(time_f * 0.9 + k * 6.28318530718);
    vec3 tint = hsv2rgb(vec3(hue, sat, val));

    float ring = smoothstep(0.0, 0.7, sin(log(r + 1e-3) * 8.0 + time_f * 1.2));
    float pulse = 0.5 + 0.5 * sin(time_f * 2.0 + r * 18.0 + k * 12.0);

    float vign = 1.0 - smoothstep(0.75, 1.2, length((tc - m) * ar));
    vign = mix(0.85, 1.2, vign);

    float blendFactor = 0.58;

    float rC = texture(samp, u0 + off).r;
    float gC = texture(samp, u1).g;
    float bC = texture(samp, u2 - off).b;
    vec3 kaleidoRGB = vec3(rC, gC, bC);

    vec4 kaleidoColor = vec4(kaleidoRGB, 1.0) * vec4(tint, 1.0);
    vec4 merged = mix(kaleidoColor, originalTexture, blendFactor);

    merged.rgb *= (0.75 + 0.25 * ring) * (0.85 + 0.15 * pulse) * vign;

    vec3 bloom = merged.rgb * merged.rgb * 0.18 + pow(max(merged.rgb - 0.6, 0.0), vec3(2.0)) * 0.12;
    vec3 outCol = merged.rgb + bloom;

    float wob = 0.9 + 0.1 * sin(time_f + r * 12.0 + k * 9.0);
    outCol *= wob;

    vec3 grad = movingGradient(tc, m, time_f, aspect);
    float gradAmt = 0.35 + 0.25 * sin(time_f * 0.5 + r * 5.0 + k * 9.0);
    vec3 screenBlend = 1.0 - (1.0 - outCol) * (1.0 - grad);
    outCol = mix(outCol, screenBlend, gradAmt);

    vec4 t = texture(samp, tc);
    outCol = mix(outCol, outCol * t.rgb, 0.8);

    outCol = sin(outCol * (0.5 + 0.5 * pingPong(time_f, 12.0)));
    outCol = clamp(outCol, vec3(0.08), vec3(0.96));

    color = vec4(outCol, 1.0);
}
