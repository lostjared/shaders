#version 330 core
// ant_gem_neon_silk
// Spiderweb silk filaments with neon fractal glow and treble shimmer

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 neon(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.20).r;
    float hiMid = texture(spectrum, 0.42).r;
    float treble = texture(spectrum, 0.60).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 p0 = p;

    // Rotation driven by bass
    p = rot(iTime * 0.3 + bass * 1.5) * p;

    // Spiderweb radial segments
    float rad = length(p) + 1e-6;
    float ang = atan(p.y, p.x);
    float N = 8.0 + floor(mid * 8.0);
    float stepA = TAU / N;
    float a = mod(ang + iTime * 0.05, stepA);
    a = abs(a - stepA * 0.5);

    // Silk strands
    float radialSilk = smoothstep(0.035, 0.0, abs(a));
    float ringSilk = smoothstep(0.05, 0.0, abs(fract(log(rad) * 2.5 + bass * 0.5 + iTime * 0.2) - 0.5));
    float web = max(radialSilk, ringSilk);

    // Kaleidoscope sample coordinates
    vec2 kaleido = vec2(cos(a), sin(a)) * rad;
    kaleido.x /= aspect;
    vec2 sampUV = kaleido + 0.5;

    // Neon fractal glow rings layered on texture
    vec3 neonAccum = vec3(0.0);
    vec2 fuv = p;
    for (float i = 0.0; i < 5.0; i++) {
        fuv = fract(fuv * (1.4 + hiMid * 0.3)) - 0.5;
        fuv = rot(iTime * 0.1 + i * 0.6) * fuv;
        fuv = abs(fuv);
        if (fuv.y > fuv.x)
            fuv = fuv.yx;

        float d = length(fuv) * exp(-length(p0));
        d = sin(d * (8.0 + treble * 6.0) + iTime) / 8.0;
        d = abs(d);
        d = pow(0.01 / d, 1.1);

        neonAccum += neon(length(p0) + i * 0.15 + iTime * 0.2) * d;
    }

    // Texture sampling with treble shimmer offset
    float shimmer = treble * 0.03 * sin(iTime * 12.0 + rad * 20.0);
    vec3 col;
    col.r = texture(samp, sampUV + vec2(shimmer, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(shimmer, 0.0)).b;

    // Blend neon glow onto silk lines
    vec3 silkGlow = neon(iTime * 0.15 + rad + bass) * web * (2.5 + air * 3.0);
    col += silkGlow * 0.4;

    // Mix fractal neon into result
    col = mix(col, col + neonAccum * 0.3, 0.4 + mid * 0.2);

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
