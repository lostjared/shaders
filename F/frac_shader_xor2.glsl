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

vec2 diamondFold(vec2 uv, vec2 c, float aspect) {
    vec2 p = (uv - c) * vec2(aspect, 1.0);
    p = abs(p);
    if (p.y > p.x)
        p = p.yx;
    p.x /= aspect;
    return p + c;
}

float diamondRadius(vec2 p) {
    p = abs(p);
    return max(p.x, p.y);
}

vec3 tentBlur3(sampler2D img, vec2 uv, vec2 res) {
    vec2 ts = 1.0 / res;
    vec3 s00 = textureGrad(img, uv + ts * vec2(-1.0, -1.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s10 = textureGrad(img, uv + ts * vec2(0.0, -1.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s20 = textureGrad(img, uv + ts * vec2(1.0, -1.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s01 = textureGrad(img, uv + ts * vec2(-1.0, 0.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s11 = textureGrad(img, uv, dFdx(uv), dFdy(uv)).rgb;
    vec3 s21 = textureGrad(img, uv + ts * vec2(1.0, 0.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s02 = textureGrad(img, uv + ts * vec2(-1.0, 1.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s12 = textureGrad(img, uv + ts * vec2(0.0, 1.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s22 = textureGrad(img, uv + ts * vec2(1.0, 1.0), dFdx(uv), dFdy(uv)).rgb;
    return (s00 + 2.0 * s10 + s20 + 2.0 * s01 + 4.0 * s11 + 2.0 * s21 + s02 + 2.0 * s12 + s22) / 16.0;
}

vec3 softTone(vec3 c) {
    c = pow(max(c, 0.0), vec3(0.95));
    float l = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(vec3(l), c, 0.9);
    return clamp(c, 0.0, 1.0);
}

/* ---- Smooth triangle (GL_SMOOTH-like) gradient ---- */

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void triPoints(out vec2 a, out vec2 b, out vec2 c) {
    vec2 cen = vec2(0.5);
    float ang = time_f * 0.25;
    float r = 0.42 + 0.03 * sin(time_f * 0.7);
    a = cen + (rot(ang) * vec2(0.0, r));
    b = cen + (rot(ang + 2.0944) * vec2(0.0, r));
    c = cen + (rot(ang + 4.1888) * vec2(0.0, r));
}

vec3 triColors() {
    vec3 c0 = vec3(1.0, 0.15, 0.75);
    vec3 c1 = vec3(0.10, 0.55, 1.0);
    vec3 c2 = vec3(0.10, 1.00, 0.45);
    float t = fract(time_f * 0.08);
    vec3 s0 = mix(c0, c1, smoothstep(0.00, 0.33, t));
    vec3 s1 = mix(c1, c2, smoothstep(0.33, 0.66, t));
    vec3 s2 = mix(c2, c0, smoothstep(0.66, 1.00, t));
    float a = step(t, 0.33);
    float b = step(0.33, t) * step(t, 0.66);
    float c = step(0.66, t);
    return normalize(a * s0 + b * s1 + c * s2) * 1.05;
}

vec3 triGradient(vec2 uv) {
    vec2 A, B, C;
    triPoints(A, B, C);
    vec2 v0 = B - A, v1 = C - A, v2 = uv - A;
    float d00 = dot(v0, v0);
    float d01 = dot(v0, v1);
    float d11 = dot(v1, v1);
    float d20 = dot(v2, v0);
    float d21 = dot(v2, v1);
    float denom = max(d00 * d11 - d01 * d01, 1e-6);
    float w1 = (d11 * d20 - d01 * d21) / denom;
    float w2 = (d00 * d21 - d01 * d20) / denom;
    float w0 = 1.0 - w1 - w2;
    w0 = max(w0, 0.0);
    w1 = max(w1, 0.0);
    w2 = max(w2, 0.0);
    float sum = max(w0 + w1 + w2, 1e-6);
    w0 /= sum;
    w1 /= sum;
    w2 /= sum;
    vec3 c0 = vec3(1.0, 0.15, 0.75);
    vec3 c1 = vec3(0.10, 0.55, 1.0);
    vec3 c2 = vec3(0.10, 1.00, 0.45);
    float s = fract(time_f * 0.12);
    c0 = mix(c0, c1, smoothstep(0.0, 1.0, s));
    c1 = mix(c1, c2, smoothstep(0.0, 1.0, s));
    c2 = mix(c2, c0, smoothstep(0.0, 1.0, s));
    vec3 col = w0 * c0 + w1 * c1 + w2 * c2;
    vec2 g = vec2(length(fwidth(uv)));
    vec3 col2 = w0 * c0 + w1 * c1 + w2 * c2;
    return mix(col, col2, 0.5);
}

/* ---- Pre-blend stage using smooth triangle gradient (no XOR) ---- */

vec3 preBlendColor(vec2 uv) {
    vec3 tex = tentBlur3(samp, uv, iResolution);
    vec3 gcol = triGradient(uv);
    vec3 grad = mix(tex, tex * gcol, 0.55);
    grad = softTone(grad);
    return grad;
}

vec3 gradientModulateTexture(vec2 uv) {
    vec3 tex = texture(samp, uv).rgb;
    vec3 gcol = triGradient(uv);
    vec3 mixed = mix(tex, tex * gcol, 0.6);
    vec2 ts = vec2(max(1.0 / iResolution.x, 1.0 / iResolution.y));
    vec3 nb = 0.25 * (textureGrad(samp, uv + ts, dFdx(uv), dFdy(uv)).rgb +
                      textureGrad(samp, uv - ts, dFdx(uv), dFdy(uv)).rgb +
                      textureGrad(samp, uv + ts * vec2(1, -1), dFdx(uv), dFdy(uv)).rgb +
                      textureGrad(samp, uv + ts * vec2(-1, 1), dFdx(uv), dFdy(uv)).rgb);
    return mix(mixed, nb, 0.08);
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    vec3 baseCol = preBlendColor(tc);

    float seg = 4.0 + 2.0 * sin(time_f * 0.33);
    vec2 kUV = reflectUV(tc, seg, m, aspect);
    kUV = diamondFold(kUV, m, aspect);
    float foldZoom = 1.45 + 0.55 * sin(time_f * 0.42);
    kUV = fractalFold(kUV, foldZoom, time_f, m, aspect);
    kUV = rotateUV(kUV, time_f * 0.23, m, aspect);
    kUV = diamondFold(kUV, m, aspect);

    vec2 p = (kUV - m) * ar;
    vec2 q = abs(p);
    if (q.y > q.x)
        q = q.yx;

    float base = 1.82 + 0.18 * sin(time_f * 0.2);
    float period = log(base);
    float tz = time_f * 0.65;
    float rD = diamondRadius(p) + 1e-6;
    float ang = atan(q.y, q.x) + tz * 0.35 + 0.35 * sin(rD * 18.0 + time_f * 0.6);
    float k = fract((log(rD) - tz) / period);
    float rw = exp(k * period);
    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw;

    vec2 u0 = fract(pwrap / ar + m);
    vec2 u1 = fract((pwrap * 1.045) / ar + m);
    vec2 u2 = fract((pwrap * 0.955) / ar + m);

    vec2 dir = normalize(pwrap + 1e-6);
    vec2 off = dir * (0.0015 + 0.001 * sin(time_f * 1.3)) * vec2(1.0, 1.0 / aspect);

    float vign = 1.0 - smoothstep(0.75, 1.2, length((tc - m) * ar));
    vign = mix(0.9, 1.15, vign);

    vec3 rC = preBlendColor(u0 + off);
    vec3 gC = preBlendColor(u1);
    vec3 bC = preBlendColor(u2 - off);
    vec3 kaleidoRGB = vec3(rC.r, gC.g, bC.b);

    float ring = smoothstep(0.0, 0.7, sin(log(rD + 1e-3) * 9.5 + time_f * 1.2));
    float pulse = 0.5 + 0.5 * sin(time_f * 2.0 + rD * 28.0 + k * 12.0);

    vec3 outCol = kaleidoRGB;
    outCol *= (0.75 + 0.25 * ring) * (0.85 + 0.15 * pulse) * vign;
    vec3 bloom = outCol * outCol * 0.18 + pow(max(outCol - 0.6, 0.0), vec3(2.0)) * 0.12;
    outCol += bloom;
    outCol = clamp(outCol, vec3(0.05), vec3(0.97));

    vec3 texCol = gradientModulateTexture(tc);
    vec3 gradWithTex = mix(texCol, baseCol, 0.5);
    vec3 finalCol = mix(outCol, gradWithTex, 0.5);

    color = vec4(finalCol, 1.0);
}
