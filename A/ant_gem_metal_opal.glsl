#version 330 core
// ant_gem_metal_opal
// Opalescent metallic shimmer with play-of-color and spectrum-driven iridescence

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
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Opal play-of-color: thin-film interference simulation
    // Varying thickness across surface creates shifting hues
    float thickness = noise(uv * 5.0 + time_f * 0.3) * 0.5;
    thickness += noise(uv * 10.0 - time_f * 0.2) * 0.3;
    thickness += noise(uv * 20.0 + time_f * 0.1) * 0.2;
    thickness *= 1.0 + bass * 0.6;

    // Iridescence: hue shifts with viewing angle and thickness
    float hueShift = thickness * 3.0 + angle * 0.5 + r * 2.0;
    vec3 iridescence = metalSpectrum(hueShift + time_f * 0.2);

    // Secondary play-of-color layer
    float hueShift2 = thickness * 5.0 - angle * 0.3 + time_f * 0.15;
    vec3 iridescence2 = metalSpectrum(hueShift2 + 0.5);

    // Blend layers based on mid energy
    vec3 opalColor = mix(iridescence, iridescence2, 0.5 + mid * 0.3);

    // Milky base: soft diffusion
    float milky = smoothstep(0.0, 0.5, thickness);

    // Texture sampling with soft warp
    vec2 opalWarp = vec2(thickness * 0.02, noise(uv * 7.0) * 0.02);
    vec2 sampUV = tc + opalWarp * (1.0 + mid);

    // Chromatic split
    float chroma = 0.006 + treble * 0.02;
    vec3 baseTex;
    baseTex.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    baseTex.g = texture(samp, sampUV).g;
    baseTex.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Blend opal with texture
    vec3 finalColor = mix(baseTex, baseTex * opalColor, milky * (0.4 + hiMid * 0.4));

    // Pearlescent highlight
    float highlight = pow(1.0 - r, 3.0) * (1.0 + treble * 1.5);
    finalColor += opalColor * highlight * 0.3;

    // Soft fire: internal opal glow on bass
    float fire = smoothstep(0.5, 0.2, r) * bass * 0.4;
    finalColor += metalSpectrum(time_f * 0.3 + r * 2.0) * fire;

    // Central glow
    float center = exp(-r * (5.0 - amp_smooth * 3.0));
    finalColor += vec3(1.0, 0.98, 0.95) * center * (1.3 + amp_peak * 1.8);

    // Air frequency shimmer
    float shimmer = sin(uv.x * 40.0 + uv.y * 40.0 + time_f * 5.0) * 0.5 + 0.5;
    finalColor += opalColor * shimmer * air * 0.15;

    color = vec4(finalColor, 1.0);
}
