#version 330 core
// ant_new_plasma_ocean
// Mix of ant_light_color_plasma_helix + ant_gem_fractal_ocean:
// plasma-field distorted fractal ocean with aurora palette and
// chromatic treble split.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 ocean(float t) {
    return vec3(0.1, 0.3, 0.5) + vec3(0.3, 0.4, 0.5) * cos(TAU * (vec3(1.0, 1.2, 1.0) * t + vec3(0.0, 0.25, 0.5)));
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.82).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= aspect;

    // Plasma field (from plasma_helix)
    float plasma = 0.0;
    plasma += sin((uv.x * 5.0 + iTime) * (1.0 + bass));
    plasma += sin((uv.y * 5.0 + iTime * 0.7) * (1.0 + mid));
    plasma += sin((uv.x + uv.y + iTime) * 3.0);
    plasma += cos(length(uv * 10.0 + iTime) * (2.0 + treble * 3.0));
    plasma *= 0.25;

    // Escape-time fractal seeded from plasma-warped coords
    vec2 p = uv * (0.9 + 0.35 * plasma);
    float iters = 0.0;
    const float max_iters = 42.0;
    for (float i = 0.0; i < max_iters; i++) {
        p = abs(p) / dot(p, p) - vec2(0.78 + mid * 0.3, 0.5 + 0.1 * sin(iTime * 0.3));
        if (length(p) > 20.0)
            break;
        iters++;
    }
    float ni = iters / max_iters;

    // Warped texture sample
    vec2 warp = tc + p * 0.015 + vec2(plasma * 0.04, plasma * 0.03);
    warp = fract(warp);

    float chroma = treble * 0.035;
    vec3 col;
    col.r = texture(samp, fract(warp + vec2(chroma, 0.0))).r;
    col.g = texture(samp, warp).g;
    col.b = texture(samp, fract(warp - vec2(chroma, 0.0))).b;

    // Ocean aurora layered with plasma tint
    vec3 aurora = ocean(ni * 2.0 + iTime * 0.2 + bass);
    col = mix(col, col * aurora, 0.4 + hiMid * 0.3);
    col += aurora * pow(max(plasma, 0.0), 2.0) * (0.2 + air * 0.4);

    // Deep ring glow
    float rings = pow(0.01 / max(abs(sin(ni * 8.0 + iTime)), 0.001), 0.8);
    col += aurora * rings * 0.15 * (1.0 + air);

    col *= 0.85 + amp_smooth * 0.35;
    col *= 1.0 + bass * 0.4;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
