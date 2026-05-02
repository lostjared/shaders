#version 330 core
// ant_gem_diamond_storm
// Diamond folds with fractal iterations and bass-driven particle storm

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = tc;
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);

    // Diamond fold: abs-based 45-degree symmetry
    p = abs(p);
    if (p.y > p.x)
        p = p.yx;

    // Fractal fold iterations driven by hiMid
    int folds = 3 + int(hiMid * 3.0);
    for (int i = 0; i < 6; i++) {
        if (i >= folds)
            break;
        p = abs(p) - 0.35 + bass * 0.1;
        p = rot(iTime * 0.15 + float(i) * 0.5 + mid * 0.3) * p;
        if (p.y > p.x)
            p = p.yx;
    }

    // Map to texture coordinates
    vec2 sampUV = fract(p / vec2(aspect, 1.0) + 0.5);

    // Storm particle sparkle from hash noise
    float sparkle = 0.0;
    for (float i = 0.0; i < 8.0; i++) {
        vec2 seed = floor(p * (5.0 + i * 2.0)) + i;
        float h = hash(seed + floor(iTime * 4.0));
        float freq = texture(spectrum, h * 0.5).r;
        sparkle += step(0.92 - bass * 0.1, h) * freq * 2.0;
    }

    // Chromatic aberration on treble
    float chroma = treble * 0.04;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, chroma)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, chroma)).b;

    // Diamond edge glow
    float edgeDist = min(abs(p.x), abs(p.y));
    float edgeGlow = pow(0.008 / max(edgeDist, 0.001), 0.9);
    vec3 glowCol = 0.5 + 0.5 * cos(6.28318 * (length(p) + iTime * 0.3 + vec3(0.0, 0.33, 0.67)));
    col += glowCol * edgeGlow * 0.2 * (1.0 + mid);

    // Storm sparkles
    col += vec3(0.9, 0.8, 1.0) * sparkle * 0.15;

    col *= 0.85 + amp_smooth * 0.35;
    col *= 1.0 + bass * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
