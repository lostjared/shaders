#version 330 core
// ant_gem_crystal_pulse
// Kaleidoscopic crystal facets (gem_bump) with bass-pumped zoom and spectrum color wash

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

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.65).r;
    float air = texture(spectrum, 0.85).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = tc;

    // Center and aspect-correct
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);

    // Bass-driven breathing zoom
    p *= 1.0 - bass * 0.35;

    // Mid-driven rotation
    p = rot(iTime * 0.4 + mid * 2.5) * p;

    // Crystal facets: kaleidoscope segments increase with treble
    float segments = 6.0 + floor(treble * 14.0);
    float angle = atan(p.y, p.x);
    float radius = length(p);
    float step_val = 2.0 * PI / segments;
    angle = mod(angle, step_val);
    angle = abs(angle - step_val * 0.5);

    // Inner fractal fold for depth
    vec2 crystal = vec2(cos(angle), sin(angle)) * radius;
    for (int i = 0; i < 3; i++) {
        crystal = abs(crystal) - 0.3 + bass * 0.15;
        crystal = rot(iTime * 0.1 + float(i) * 0.7) * crystal;
    }

    // Map back to texture coords
    crystal.x /= aspect;
    vec2 sampUV = crystal + 0.5;

    // Chromatic aberration driven by air frequencies
    float chroma = (air + treble) * 0.04;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Spectrum color wash
    vec3 specWash = 0.5 + 0.5 * cos(6.28318 * (radius - iTime * 0.3 + vec3(0.0, 0.33, 0.67)));
    col = mix(col, col * specWash, 0.3 + mid * 0.3);

    // Pulse brightness with bass
    col *= 1.0 + bass * 0.6;

    // Peak inversion
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    // Smooth brightness ride
    col *= 0.85 + amp_smooth * 0.3;

    color = vec4(col, 1.0);
}
