#version 330 core
// ant_new_kaleido_fractal
// Mix of ant_spectrum_kaleido_flame + ant_gem_fractal_ocean:
// kaleidoscope petals sampled through an escape-time fractal warp
// tinted with rainbow and aurora ocean palette.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}
vec3 ocean(float t) {
    return vec3(0.1, 0.3, 0.5) + vec3(0.3, 0.4, 0.5) * cos(6.28318 * (vec3(1.0, 1.2, 1.0) * t + vec3(0.0, 0.25, 0.5)));
}

vec2 kaleidoscope(vec2 p, float seg) {
    float ang = atan(p.y, p.x);
    float r = length(p);
    float s = 2.0 * PI / seg;
    ang = abs(mod(ang, s) - s * 0.5);
    return vec2(cos(ang), sin(ang)) * r;
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.82).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0) * 2.0;

    // Kaleidoscope on raw uv
    float seg = floor(6.0 + bass * 8.0);
    vec2 kUV = kaleidoscope(uv, seg);
    kUV = abs(kUV);
    if (kUV.y > kUV.x)
        kUV = kUV.yx;

    // Fractal escape on kaleidoscoped coords
    vec2 p = kUV * (0.75 + 0.3 * mid);
    float iters = 0.0;
    const float maxI = 40.0;
    for (float i = 0.0; i < maxI; i++) {
        p = abs(p) / dot(p, p) - vec2(0.78 + hiMid * 0.25, 0.5 + 0.1 * sin(iTime * 0.3));
        if (length(p) > 20.0)
            break;
        iters++;
    }
    float ni = iters / maxI;

    // Sample texture with fractal-warped uv
    vec2 sampUV = fract(tc + p * 0.02);
    float chroma = treble * 0.04;
    vec3 col;
    col.r = texture(samp, fract(sampUV + vec2(chroma, 0.0))).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, fract(sampUV - vec2(chroma, 0.0))).b;

    // Dual palette blend: warm rainbow + cool ocean
    vec3 warm = rainbow(ni + iTime * 0.3 + bass);
    vec3 cool = ocean(ni * 2.0 + iTime * 0.2);
    vec3 paint = mix(cool, warm, 0.3 + hiMid * 0.5);
    col = mix(col, col * paint * 1.2, 0.35 + mid * 0.3);

    // Inner glow rings keyed off fractal depth
    float rings = pow(0.01 / max(abs(sin(ni * 8.0 + iTime)), 0.001), 0.8);
    col += paint * rings * 0.18 * (1.0 + air);

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
