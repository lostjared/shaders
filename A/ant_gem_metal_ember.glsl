#version 330 core
// ant_gem_metal_ember
// Glowing metallic embers with heat distortion and spectrum-driven flicker

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

vec3 ember(float t) {
    vec3 a = vec3(0.6, 0.15, 0.02);
    vec3 b = vec3(0.4, 0.25, 0.08);
    vec3 c = vec3(1.0, 0.8, 0.4);
    vec3 d = vec3(0.0, 0.15, 0.25);
    return a + b * cos(6.28318 * (c * t + d));
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
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Heat shimmer distortion driven by mid
    float heatNoise = noise(uv * 8.0 + vec2(0.0, -time_f * 3.0));
    vec2 heatWarp = vec2(heatNoise - 0.5, heatNoise - 0.5) * (0.02 + mid * 0.04);

    // Ripple from base shader
    float ripple = sin(angle * 8.0 + time_f) * (0.03 + bass * 0.05);
    ripple += sin(r * 15.0 - time_f * 4.0) * (0.02 + treble * 0.03);

    // Chromatic split
    float shift = ripple * 0.3 + air * 0.01;
    vec2 warpedTC = tc + heatWarp;
    vec3 baseTex;
    baseTex.r = texture(samp, warpedTC + vec2(shift, 0.0)).r;
    baseTex.g = texture(samp, warpedTC).g;
    baseTex.b = texture(samp, warpedTC - vec2(shift, 0.0)).b;

    // Ember particles
    vec2 grid = floor(uv * 15.0);
    float particle = hash(grid + floor(time_f * 2.0));
    float isEmber = step(0.92 - bass * 0.1, particle);
    vec2 cell = fract(uv * 15.0) - 0.5;
    float emberGlow = isEmber * exp(-length(cell) * 8.0);

    // Ember color from heat palette
    vec3 emberColor = ember(particle + time_f * 0.5 + bass);
    vec3 particles = emberColor * emberGlow * (3.0 + hiMid * 4.0);

    // Metallic wave overlay
    float wave = sin(r * (20.0 + mid * 10.0) - time_f * 4.0 + ripple * 8.0);
    vec3 metalWave = metalSpectrum(r + time_f * 0.2) * smoothstep(0.5, 1.0, wave) * 0.3;

    // Central glow
    float lightRadius = 5.0 - amp_smooth * 3.0;
    float center = exp(-r * max(lightRadius, 0.5));
    vec3 coreGlow = vec3(1.0, 0.85, 0.6) * center * (1.5 + amp_peak * 2.5);

    vec3 finalColor = baseTex + metalWave + particles + coreGlow;
    finalColor += ripple * wave * (1.0 + bass * 2.0);

    color = vec4(finalColor, 1.0);
}
