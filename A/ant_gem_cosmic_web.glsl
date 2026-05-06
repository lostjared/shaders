#version 330 core
// ant_gem_cosmic_web
// Spiderweb + deep fractal + cosmic palette with full spectrum band reactivity

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

vec3 cosmic(float t) {
    vec3 a = vec3(0.2, 0.1, 0.3);
    vec3 b = vec3(0.5, 0.4, 0.5);
    vec3 c = vec3(1.0, 1.5, 1.2);
    vec3 d = vec3(0.0, 0.1, 0.4);
    return a + b * cos(TAU * (c * t + d));
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float lowMid = texture(spectrum, 0.10).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 p0 = p;

    // Bass-driven rotation
    p = rot(iTime * 0.25 + bass * 1.0) * p;

    // Log-polar tunnel from spiderweb
    float rad = length(p) + 1e-6;
    float ang = atan(p.y, p.x);
    float base = 1.72 + bass * 1.8;
    float period = log(base);
    float t = iTime * 0.35;
    float k = fract((log(rad) - t) / period);
    float rw = exp(k * period);
    vec2 qwrap = vec2(cos(ang + t * 0.15), sin(ang + t * 0.15)) * rw;

    // Web kaleidoscope
    float N = 8.0 + floor(mid * 6.0);
    float stepA = TAU / N;
    float a = mod(atan(qwrap.y, qwrap.x) + iTime * 0.04, stepA);
    a = abs(a - stepA * 0.5);
    vec2 kaleido = vec2(cos(a), sin(a)) * length(qwrap);

    // Deep fractal escape within kaleidoscope
    vec2 fp = kaleido * 2.0;
    float iters = 0.0;
    const float maxIters = 30.0;
    for (float i = 0.0; i < maxIters; i++) {
        fp = abs(fp) / dot(fp, fp) - vec2(0.8 + lowMid * 0.2, 0.5);
        if (length(fp) > 15.0)
            break;
        iters++;
    }
    float norm = iters / maxIters;

    // Texture mapping
    vec2 sampUV = fract(kaleido / vec2(aspect, 1.0) + 0.5 + fp * 0.01);

    // Chromatic split on treble+air
    float chroma = (treble + air) * 0.04;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Silk web filaments
    float radialSilk = smoothstep(0.035, 0.0, abs(a));
    float ringSilk = smoothstep(0.05, 0.0, abs(fract(log(rad) * 2.0 + bass) - 0.5));
    float web = max(radialSilk, ringSilk);

    // Cosmic palette on web + fractal depth
    vec3 cosCol = cosmic(norm + iTime * 0.1 + bass);
    col += cosCol * web * (1.5 + treble * 2.0) * mid;

    // Deep fractal color tinting
    col = mix(col, col * cosCol, 0.3 + hiMid * 0.25);

    // Neon glow at fractal boundary
    float boundaryGlow = pow(0.01 / max(abs(norm - 0.5), 0.001), 0.5);
    col += cosCol * boundaryGlow * 0.06 * (1.0 + air);

    // Echo samples from spectrum
    for (float e = 1.0; e < 4.0; e++) {
        float freq = texture(spectrum, e * 0.08).r;
        vec2 off = vec2(freq * 0.02 * e, 0.0) * rot(iTime + e);
        col += texture(samp, abs(fract((sampUV + off) * 0.5 + 0.5) * 2.0 - 1.0)).rgb * (0.12 / e);
    }

    col *= 0.85 + amp_smooth * 0.3;
    col *= 1.0 + bass * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
