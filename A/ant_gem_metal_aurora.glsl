#version 330 core
// ant_gem_metal_aurora
// Aurora borealis curtains over metallic gem surface with spectrum-driven sway

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

vec3 metalSpectrum(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67))));
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

void main(void) {
    float bass = texture(spectrum, 0.04).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Aurora curtain waves driven by bass
    float curtain = 0.0;
    for (float i = 1.0; i < 5.0; i++) {
        float freq = i * 3.0 + bass * 4.0;
        float speed = time_f * (0.5 + i * 0.3);
        float n = noise(vec2(uv.x * freq + speed, i * 7.3));
        curtain += n * (0.3 / i);
    }
    curtain *= 1.0 + mid * 1.5;

    // Vertical aurora bands sway with treble
    float sway = sin(uv.x * 8.0 + time_f * 2.0 + treble * 4.0) * 0.1;
    float band = smoothstep(0.3 + sway, 0.6 + sway, uv.y + curtain);
    band *= smoothstep(-0.2, 0.1, uv.y + curtain);

    // Metallic gem ripples
    float ripple = sin(angle * 10.0 + time_f) * (0.03 + bass * 0.05);
    ripple += sin(r * 20.0 - time_f * 3.0) * 0.02;

    // Chromatic split
    float shift = ripple * 0.5 + air * 0.01;
    vec3 baseTex;
    baseTex.r = texture(samp, tc + vec2(shift, 0.0)).r;
    baseTex.g = texture(samp, tc).g;
    baseTex.b = texture(samp, tc - vec2(shift, 0.0)).b;

    // Aurora color: green-cyan-purple spectrum
    vec3 auroraColor = metalSpectrum(curtain + time_f * 0.1 + r * 0.5);
    auroraColor *= vec3(0.3, 1.0, 0.7); // bias toward green/cyan

    // Central metallic glow
    float lightRadius = 5.0 - amp_smooth * 3.0;
    float center = exp(-r * max(lightRadius, 0.5));
    vec3 coreGlow = vec3(0.9, 1.0, 0.95) * center * (1.5 + amp_peak * 2.0);

    vec3 finalColor = baseTex;
    finalColor = mix(finalColor, finalColor + auroraColor, band * (0.5 + mid * 0.4));
    finalColor += coreGlow;
    finalColor += ripple * (1.0 + bass * 2.0);

    color = vec4(finalColor, 1.0);
}
