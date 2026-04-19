#version 330 core
// ant_gem_metal_crystal
// Crystalline metallic facets with fractal folds and spectrum-colored reflections

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 metalSpectrum(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67))));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main(void) {
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);

    // Bass breathing zoom
    p *= 1.0 - bass * 0.3;

    // Mid-driven rotation
    p = rot(time_f * 0.3 + mid * 2.0) * p;

    // Crystal facets via kaleidoscope
    float segments = 6.0 + floor(treble * 10.0);
    float angle = atan(p.y, p.x);
    float radius = length(p);
    float stepVal = 2.0 * PI / segments;
    angle = mod(angle, stepVal);
    angle = abs(angle - stepVal * 0.5);

    vec2 crystal = vec2(cos(angle), sin(angle)) * radius;

    // Fractal fold iterations
    for (int i = 0; i < 4; i++) {
        crystal = abs(crystal) - 0.25 + bass * 0.1;
        crystal = rot(time_f * 0.15 + float(i) * 0.8) * crystal;
    }

    // Map to texture
    vec2 sampUV = crystal / vec2(aspect, 1.0) + 0.5;

    // Chromatic aberration on air
    float chroma = (air + treble) * 0.035;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Metallic spectrum wash
    vec3 specWash = metalSpectrum(radius - time_f * 0.25 + mid * 0.5);
    col = mix(col, col * specWash, 0.35 + mid * 0.3);

    // Facet edge glow
    float edgeDist = abs(fract(angle / stepVal * segments) - 0.5);
    float edgeGlow = smoothstep(0.02, 0.0, edgeDist) * (0.5 + treble);
    col += metalSpectrum(time_f * 0.3 + radius) * edgeGlow * 0.4;

    // Central bright core
    float center = exp(-radius * (5.0 - amp_smooth * 3.0));
    col += vec3(1.0, 0.98, 0.93) * center * (1.5 + amp_peak * 2.0);

    col *= 0.85 + amp_smooth * 0.3;

    color = vec4(col, 1.0);
}
