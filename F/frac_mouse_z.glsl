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

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec2 warp(vec2 uv, float t) {
    float s1 = sin((uv.x + uv.y) * 8.0 + t * 0.8);
    float s2 = cos((uv.x - uv.y) * 9.0 - t * 0.6);
    float s3 = sin((uv.x * 2.0) * 5.0 + t * 1.1) + cos((uv.y * 2.0) * 7.0 - t * 1.3);
    return uv + 0.02 * vec2(s1 + s3 * 0.5, s2 - s3 * 0.5);
}

vec2 logPolarWrap(vec2 uv, vec2 c, vec2 ar, float tz, float base) {
    vec2 p = (uv - c) * ar;
    float r = length(p) + 1e-6;
    float a = atan(p.y, p.x) + tz * 0.3;
    float per = log(base);
    float k = fract((log(r) - tz) / per);
    float rw = exp(k * per);
    vec2 q = vec2(cos(a), sin(a)) * rw;
    return fract(q / ar + c);
}

vec2 fold(vec2 uv, float zoom, float t, vec2 c, float aspect) {
    vec2 p = uv;
    for (int i = 0; i < 7; i++) {
        p = abs((p - c) * zoom) - 0.5 + c;
        p = rotateUV(p, t * 0.12 + float(i) * 0.05, c, aspect);
        p = warp(p, t + float(i) * 0.37);
    }
    return p;
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 uv = tc;

    vec4 baseTex = texture(samp, tc);

    float seg = mix(5.0, 12.0, 0.5 + 0.5 * sin(time_f * 0.35));
    vec2 kUV = reflectUV(uv, seg, m, aspect);

    float mouseAmp = (iMouse.z > 0.5) ? (0.3 + 0.4 * abs(sin((iMouse.x + iMouse.y) * 0.001 + time_f * 0.2))) : 0.45;
    float foldZoom = 1.35 + 0.45 * sin(time_f * 0.45) + mouseAmp * 0.25;
    kUV = fold(kUV, foldZoom, time_f, m, aspect);
    kUV = rotateUV(kUV, time_f * 0.22, m, aspect);

    float tz = time_f * 0.6;
    float base = 1.72 + 0.2 * sin(time_f * 0.2);
    vec2 zp0 = logPolarWrap(kUV, m, ar, tz, base);
    vec2 zp1 = logPolarWrap(kUV + 0.003 * vec2(1.0, 0.0), m, ar, tz + 0.08, base);
    vec2 zp2 = logPolarWrap(kUV + 0.003 * vec2(0.0, 1.0), m, ar, tz + 0.16, base);

    vec2 zpw0 = warp(zp0, time_f);
    vec2 zpw1 = warp(zp1, time_f + 0.7);
    vec2 zpw2 = warp(zp2, time_f + 1.4);

    vec4 s0 = texture(samp, zpw0);
    vec4 s1 = texture(samp, zpw1);
    vec4 s2 = texture(samp, zpw2);

    vec3 chroma = vec3(s0.r, s1.g, s2.b);

    float ring = sin(10.0 * length((kUV - m) * ar) - time_f * 3.0) * 0.5 + 0.5;
    float swirl = sin(6.2831853 * (zpw0.x + zpw0.y) + time_f * 1.4) * 0.5 + 0.5;
    float mask = smoothstep(0.0, 1.0, ring * 0.6 + swirl * 0.4);

    vec3 hsv = vec3(fract(time_f * 0.07 + ring * 0.25 + swirl * 0.25), 0.8, 0.9);
    vec3 rainbow = hsv2rgb(hsv);

    vec3 kaleido = mix(chroma, chroma * rainbow, 0.65);
    vec4 kaleidoTex = vec4(kaleido, 1.0);

    float blendFactor = 0.55 + 0.15 * sin(time_f * 0.33);
    vec4 mixA = mix(kaleidoTex, baseTex, blendFactor * (0.6 + 0.4 * mask));

    vec3 pulse = 0.5 + 0.5 * sin(vec3(1.7, 2.3, 3.1) * time_f + (zpw0.xyx + zpw0.yxx) * 9.0);
    vec4 glow = vec4(mixA.rgb * pulse, 1.0);

    vec4 mod1 = sin(glow * (1.0 + 0.7 * pingPong(time_f, 9.0)));
    vec4 mod2 = sin(mod1 * (1.0 + 0.9 * pingPong(time_f, 13.0)));

    vec4 t = texture(samp, tc);
    vec4 outc = mod2 * t * (0.7 + 0.3 * mask);

    outc.rgb = clamp(outc.rgb, 0.08, 0.92);
    color = vec4(outc.rgb, 1.0);
}
