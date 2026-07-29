#version 330 core
// ant_gem_aurora_tunnel
// Log-polar tunnel with aurora curtain overlays and bass-driven depth stretching

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 aurora(float t) {
    vec3 a = vec3(0.1, 0.4, 0.3);
    vec3 b = vec3(0.3, 0.5, 0.4);
    vec3 c = vec3(1.0, 1.2, 1.5);
    vec3 d = vec3(0.0, 0.15, 0.4);
    return a + b * cos(TAU * (c * t + d));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

mat3 rotY(float a) { float s=sin(a),c=cos(a); return mat3(c,0,s, 0,1,0, -s,0,c); }
mat3 rotZ(float a) { float s=sin(a),c=cos(a); return mat3(c,-s,0, s,c,0, 0,0,1); }

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.20).r;
    float hiMid  = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);

    // 3D perspective rotation
    vec3 v = vec3(p, 1.0);
    mat3 R = rotZ(iTime * 0.3 + bass * 0.5) * rotY(sin(iTime * 0.5) * 0.2);
    vec3 r = R * v;
    float persp = 0.6 + amp_smooth * 0.4;
    float zf = 1.0 / (1.0 + r.z * persp);
    vec2 q = r.xy * zf;

    // Log-polar tunnel with bass-stretched depth
    float rad = length(q) + 1e-6;
    float ang = atan(q.y, q.x);
    float base = 1.72 + bass * 2.0;
    float period = log(base);
    float t = iTime * 0.5;
    float k = fract((log(rad) - t) / period);
    float rw = exp(k * period);
    vec2 qwrap = vec2(cos(ang + t * 0.2), sin(ang + t * 0.2)) * rw;

    // Kaleidoscope
    float N = 6.0 + floor(mid * 6.0);
    float stepA = TAU / N;
    float a = mod(atan(qwrap.y, qwrap.x), stepA);
    a = abs(a - stepA * 0.5);
    vec2 kaleido = vec2(cos(a), sin(a)) * length(qwrap);
    kaleido.x /= aspect;
    vec2 sampUV = fract(kaleido + 0.5);

    // Sample texture
    vec3 col = texture(samp, sampUV).rgb;

    // Aurora curtain overlays
    vec3 auroraGlow = vec3(0.0);
    vec2 centered = tc - 0.5;
    for (float i = 0.0; i < 5.0; i++) {
        float yOff = i * 0.04 + noise(vec2(centered.x * 6.0 + i, iTime * 0.3 + i)) * 0.06;
        float streak = exp(-pow((centered.y - yOff - 0.05) * 9.0, 2.0));
        float freq = texture(spectrum, i * 0.1 + 0.02).r;
        auroraGlow += aurora(i * 0.18 + iTime * 0.15 + freq) * streak * (1.0 + freq);
    }

    col += auroraGlow * (0.35 + treble * 0.3);

    // Chromatic shift on hiMid
    float chroma = hiMid * 0.03;
    col.r = mix(col.r, texture(samp, sampUV + vec2(chroma, 0.0)).r, 0.5);
    col.b = mix(col.b, texture(samp, sampUV - vec2(chroma, 0.0)).b, 0.5);

    // Bass coloring
    col += vec3(bass * 0.3, 0.0, bass * 0.15);

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
