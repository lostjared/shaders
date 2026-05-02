#version 330 core
// ant_gem_fire_spoke
// Fractal spoke glow with fire palette and bass-driven flicker/pulse

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

vec3 fire(float t) {
    vec3 a = vec3(0.5, 0.2, 0.05);
    vec3 b = vec3(0.5, 0.3, 0.1);
    vec3 c = vec3(1.0, 0.7, 0.3);
    vec3 d = vec3(0.0, 0.2, 0.3);
    return a + b * cos(6.28318 * (c * t + d));
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc * 2.0 - 1.0);
    uv.x *= aspect;

    // Bass flicker zoom
    float flicker = 1.0 + bass * 0.4 * sin(iTime * 20.0 + bass * 10.0);
    uv *= flicker;

    vec3 spokeAccum = vec3(0.0);
    float scale = 1.0;
    vec2 fuv = uv;

    // Iterative spoke fractal (from gem-spoke)
    for (int i = 0; i < 6; i++) {
        fuv = abs(fuv) - 0.5 + bass * 0.08;
        float a = iTime * 0.3 + float(i) * 0.4 + mid * 0.2;
        fuv = rot(a) * fuv;
        fuv *= 1.2;
        scale *= 1.2;

        float d = length(fuv);
        float glow = 0.01 / abs(sin(d * (8.0 + treble * 5.0) - iTime) / 8.0);

        // Fire palette instead of cold blue
        vec3 fireCol = fire(d * 0.5 + float(i) * 0.15 + iTime * 0.1 + bass);
        spokeAccum += fireCol * glow / scale;
    }

    // Texture sampling through fractal field
    vec2 sampUV = fract(fuv * 0.08 + tc);

    // Chromatic split driven by mid
    float chroma = (mid + treble) * 0.03;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Blend fire spokes with texture
    col = mix(col, col * spokeAccum, 0.5 + hiMid * 0.3);

    // Ember particles on air frequencies
    float ember = step(0.96, fract(sin(dot(floor(uv * 20.0), vec2(12.9898, 78.233))) * 43758.5453));
    col += fire(iTime + length(uv)) * ember * air * 2.0;

    // Vignette
    float vignette = smoothstep(1.5, 0.4, length(tc * 2.0 - 1.0));
    col *= vignette;

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
