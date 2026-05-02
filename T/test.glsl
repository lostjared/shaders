#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;
uniform float iTime;
uniform int iFrame;
uniform float iTimeDelta;
uniform vec4 iDate;
uniform vec2 iMouseClick;
uniform float iFrameRate;
uniform vec3 iChannelResolution[4];
uniform float iChannelTime[4];
uniform float iSampleRate;

float hash(float n) { return fract(sin(n) * 43758.5453123); }
float n2(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    float a = hash(i.x + i.y * 57.0);
    float b = hash(i.x + 1.0 + (i.y) * 57.0);
    float c = hash(i.x + (i.y + 1.0) * 57.0);
    float d = hash(i.x + 1.0 + (i.y + 1.0) * 57.0);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
float pingPong(float x, float l) {
    float m = mod(x, l * 2.0);
    return m <= l ? m : l * 2.0 - m;
}

void main() {
    vec2 R = iResolution;
    vec2 uv = tc;
    vec2 cn = R.xy / max(R.x, R.y);
    vec2 m = vec2(iMouse.x / iResolution.x, iMouse.y / iResolution.y);
    m = clamp(m, 0.0, 1.0);
    float t = time_f + iTime + float(iFrame) * iTimeDelta * 0.25;
    float fr = max(iFrameRate, 1.0);
    float dateSeed = dot(iDate, vec4(1.0, 31.0, 12.0, 0.001));
    float chs = 0.0;
    for (int i = 0; i < 4; i++) {
        chs += sin(iChannelTime[i] * 0.73 + float(i) * 1.1) +
               0.001 * length(iChannelResolution[i].xy) +
               0.000001 * iChannelResolution[i].z;
    }
    float sr = clamp(iSampleRate / 48000.0, 0.25, 2.0);
    float aMix = clamp(amp * 0.5 + uamp * 0.5, 0.0, 10.0);

    vec2 c = m * 0.75 + 0.125;
    float clickT = length(iMouseClick - 0.5) * 2.0;
    float speed = 0.2 + 0.4 * sr + 0.15 * sin(dateSeed);
    float kSides = 3.0 + mod(float(iFrame), 9.0);
    vec2 p = (uv - c);
    p.x *= R.x / R.y;

    float r = length(p);
    float ang = atan(p.y, p.x);
    ang = abs(fract(ang / 3.14159265 * kSides) * 2.0 - 1.0);
    float kale = sin(ang * 6.28318 + chs * 0.5 + t * 2.0);

    float ripple = sin(20.0 * r - t * 12.0 - clickT * 10.0) * 0.02 * (1.0 / (1.0 + 20.0 * r));
    float swirl = (kale * 0.25 + 0.25) * r;
    float wave = sin((uv.x + uv.y * 1.7 + chs * 0.1 + t * speed * fr * 0.01) * 40.0 * sr) * 0.005;

    vec2 nWarp = vec2(n2(uv * 8.0 + vec2(t)), n2(uv * 8.0 + vec2(-t)));
    vec2 warp = (nWarp - 0.5) * 0.08 * aMix;

    vec2 uv1 = uv + warp + vec2(wave, -wave) + normalize(p + 0.0001) * ripple;
    vec2 uv2 = uv + vec2(swirl, -swirl) * 0.15 * aMix;
    vec2 uv3 = uv + vec2(sin(t + uv.y * 10.0), cos(t + uv.x * 10.0)) * 0.01 * (1.0 + 0.5 * sin(dateSeed + chs));

    float zoom = 0.9 + 0.2 * sin(pingPong(t * 0.5 + chs, 2.0) * 3.14159);
    uv1 = (uv1 - c) * zoom + c;
    uv2 = (uv2 - c) * zoom + c;
    uv3 = (uv3 - c) * zoom + c;

    vec4 s1 = texture(samp, fract(uv1));
    vec4 s2 = texture(samp, fract(uv2));
    vec4 s3 = texture(samp, fract(uv3));

    float hueBase = fract(t * 0.05 + dateSeed * 0.1 + chs * 0.05);
    float sat = 0.75 + 0.25 * sin(chs + t + sr);
    float val = 0.6 + 0.4 * sin(t * 0.7 + dot(uv, vec2(3.1, 2.7)));
    vec3 tint = hsv2rgb(vec3(hueBase + length(p) * 0.25 + 0.1 * sin(iTimeDelta * 60.0), sat, val));

    vec4 mixA = mix(s1, s2, 0.5 + 0.5 * sin(t + chs));
    vec4 mixB = mix(s2, s3, 0.5 + 0.5 * cos(t * 1.3));
    vec4 mixC = mix(mixA, mixB, 0.5 + 0.5 * sin(t * 0.7 + dateSeed));

    float vign = 1.0 - smoothstep(0.6, 1.1, r);
    vec3 col = mixC.rgb * tint * (0.8 + 0.2 * sin(float(iFrame) * 0.01 + chs)) + 0.25 * tint;
    col *= vign;

    color = vec4(col, 1.0);
}
