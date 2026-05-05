#version 330 core
// ant_gem_metal_glacier
// Icy metallic reflections with slow fracture drift and cool spectrum tones

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
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Ice fracture: layered noise for crack-like patterns
    float ice = 0.0;
    float amp = 0.5;
    vec2 iceUV = uv * 3.0;
    for (int i = 0; i < 5; i++) {
        ice += abs(noise(iceUV) - 0.5) * amp;
        iceUV *= 2.1;
        iceUV += vec2(time_f * 0.1, time_f * 0.05);
        amp *= 0.5;
    }
    ice *= 1.0 + bass * 1.0;

    // Slow glacial drift
    vec2 drift = vec2(sin(time_f * 0.2), cos(time_f * 0.15)) * 0.01;
    drift *= 1.0 + mid * 2.0;

    // Cool metallic ripple
    float ripple = sin(r * (18.0 + mid * 8.0) - time_f * 2.0) * 0.02;

    // Chromatic split for icy refraction
    float shift = ripple + ice * 0.01 + treble * 0.01;
    vec2 sampUV = tc + drift;
    vec3 baseTex;
    baseTex.r = texture(samp, sampUV + vec2(shift, shift * 0.5)).r;
    baseTex.g = texture(samp, sampUV).g;
    baseTex.b = texture(samp, sampUV - vec2(shift * 0.5, shift)).b;

    // Cool blue-silver tint
    vec3 iceTint = vec3(0.7, 0.85, 1.0);
    baseTex = mix(baseTex, baseTex * iceTint, 0.3 + air * 0.2);

    // Ice crystal highlights from fracture ridges
    float ridge = smoothstep(0.15, 0.12, ice) * (1.0 + treble * 1.5);
    vec3 ridgeColor = metalSpectrum(ice + time_f * 0.1) * vec3(0.6, 0.8, 1.0);

    vec3 finalColor = baseTex + ridgeColor * ridge * 0.5;

    // Frost sparkle
    float sparkle = pow(noise(uv * 50.0 + time_f * 0.5), 12.0);
    finalColor += vec3(0.8, 0.9, 1.0) * sparkle * (3.0 + hiMid * 4.0);

    // Central cold glow
    float center = exp(-r * (5.0 - amp_smooth * 3.0));
    finalColor += vec3(0.85, 0.95, 1.0) * center * (1.5 + amp_peak * 2.0);

    color = vec4(finalColor, 1.0);
}
