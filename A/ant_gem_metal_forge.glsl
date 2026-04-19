#version 330 core
// ant_gem_metal_forge
// Molten forge glow with hammered metal texture and bass-pumped heat waves

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

vec3 forgePalette(float t) {
    // Dark iron -> orange glow -> white hot
    vec3 a = vec3(0.1, 0.05, 0.02);
    vec3 b = vec3(0.8, 0.4, 0.1);
    vec3 c = vec3(1.0, 0.6, 0.2);
    vec3 d = vec3(0.0, 0.25, 0.4);
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

    // Hammered metal: irregular bumps
    float hammer = noise(uv * 12.0 + time_f * 0.3);
    hammer += noise(uv * 24.0 - time_f * 0.5) * 0.5;
    hammer *= 0.5 + bass * 0.5;

    // Heat wave distortion
    float heatWave = sin(r * (15.0 + mid * 12.0) - time_f * (5.0 + amp_peak * 3.0));
    vec2 heatDir = vec2(cos(angle), sin(angle));
    vec2 warpedTC = tc + heatDir * heatWave * (0.01 + bass * 0.02);
    warpedTC += vec2(hammer * 0.01);

    // Chromatic split
    float chroma = 0.01 + treble * 0.025;
    vec3 baseTex;
    baseTex.r = texture(samp, warpedTC + vec2(chroma, 0.0)).r;
    baseTex.g = texture(samp, warpedTC).g;
    baseTex.b = texture(samp, warpedTC - vec2(chroma, 0.0)).b;

    // Forge heat coloring
    float heat = smoothstep(0.3, 0.0, r) * (1.0 + bass * 1.5);
    heat += hammer * 0.3;
    vec3 forgeColor = forgePalette(heat + time_f * 0.1);

    // Metallic reflection
    vec3 metalRefl = metalSpectrum(angle / 6.28318 + time_f * 0.15);
    float reflMask = smoothstep(0.4, 0.8, heatWave);

    vec3 finalColor = mix(baseTex, forgeColor, heat * 0.6);
    finalColor = mix(finalColor, finalColor * metalRefl, reflMask * (0.3 + hiMid * 0.3));

    // Sparks on air frequency
    float spark = step(0.97, hash(floor(uv * 30.0) + floor(time_f * 8.0)));
    finalColor += vec3(1.0, 0.9, 0.5) * spark * air * 4.0;

    // Central forge glow
    float center = exp(-r * (4.0 - amp_smooth * 2.5));
    finalColor += vec3(1.0, 0.7, 0.3) * center * (2.0 + amp_peak * 3.0);

    color = vec4(finalColor, 1.0);
}
