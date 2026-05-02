#version 330 core
// ant_gem_metal_inferno
// Intense heat glow with metal warping and spectrum-driven flame intensity

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

vec3 inferno(float t) {
    // black -> red -> orange -> yellow -> white
    t = clamp(t, 0.0, 1.0);
    vec3 c = vec3(0.0);
    c = mix(c, vec3(0.5, 0.0, 0.0), smoothstep(0.0, 0.25, t));
    c = mix(c, vec3(1.0, 0.3, 0.0), smoothstep(0.25, 0.5, t));
    c = mix(c, vec3(1.0, 0.8, 0.2), smoothstep(0.5, 0.75, t));
    c = mix(c, vec3(1.0, 1.0, 0.9), smoothstep(0.75, 1.0, t));
    return c;
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
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Rising flame distortion
    float flame1 = noise(vec2(uv.x * 4.0, uv.y * 3.0 - time_f * 4.0));
    float flame2 = noise(vec2(uv.x * 8.0 + 3.0, uv.y * 6.0 - time_f * 6.0));
    float flameField = flame1 * 0.6 + flame2 * 0.4;
    flameField *= 1.0 + bass * 1.5;

    // Warp texture with flame
    vec2 flameWarp = vec2(
        (flame1 - 0.5) * (0.04 + mid * 0.06),
        (flame2 - 0.5) * (0.03 + bass * 0.05));
    vec2 sampUV = tc + flameWarp;

    // Chromatic split
    float chroma = 0.01 + treble * 0.03;
    vec3 baseTex;
    baseTex.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    baseTex.g = texture(samp, sampUV).g;
    baseTex.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Heat intensity based on position and audio
    float heat = smoothstep(1.0, 0.0, r) * (0.5 + bass * 0.5);
    heat += flameField * 0.4;
    heat = clamp(heat, 0.0, 1.0);

    vec3 infernoColor = inferno(heat);

    // Metallic sheen over the hot zones
    float metalMask = smoothstep(0.3, 0.7, heat);
    vec3 metalRefl = metalSpectrum(angle / 6.28318 + time_f * 0.15 + r);

    vec3 finalColor = mix(baseTex, infernoColor, heat * 0.6);
    finalColor = mix(finalColor, finalColor * metalRefl, metalMask * (0.3 + hiMid * 0.3));

    // Intense central core
    float center = exp(-r * (3.0 - amp_smooth * 2.0));
    finalColor += vec3(1.0, 0.9, 0.6) * center * (2.0 + amp_peak * 3.0);

    // Air sparkle
    float spark = step(0.96, hash(floor(uv * 25.0) + floor(time_f * 6.0)));
    finalColor += vec3(1.0, 0.95, 0.7) * spark * air * 3.0;

    color = vec4(finalColor, 1.0);
}
