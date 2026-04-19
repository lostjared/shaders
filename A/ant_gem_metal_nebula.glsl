#version 330 core
// ant_gem_metal_nebula
// Space nebula with metallic dust clouds and spectrum-driven star formation

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

float fbm(vec2 p) {
    float f = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 5; i++) {
        f += noise(p) * amp;
        p *= 2.1;
        amp *= 0.5;
    }
    return f;
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

    // Nebula gas clouds via fbm
    float nebula1 = fbm(uv * 2.0 + time_f * 0.2);
    float nebula2 = fbm(uv * 3.0 - time_f * 0.15 + 5.0);
    float nebulaMix = nebula1 * 0.6 + nebula2 * 0.4;
    nebulaMix *= 1.0 + bass * 0.8;

    // Swirl driven by mid
    float swirl = sin(angle * 3.0 + r * (6.0 + mid * 5.0) - time_f * 1.5);

    // Texture warp through nebula
    vec2 nebulaWarp = vec2(nebula1 - 0.5, nebula2 - 0.5) * (0.03 + mid * 0.04);
    vec2 sampUV = tc + nebulaWarp;

    // Chromatic split for gas refraction
    float chroma = 0.01 + treble * 0.025;
    vec3 baseTex;
    baseTex.r = texture(samp, sampUV + vec2(chroma, chroma * 0.5)).r;
    baseTex.g = texture(samp, sampUV).g;
    baseTex.b = texture(samp, sampUV - vec2(chroma * 0.5, chroma)).b;

    // Nebula coloring: purple/blue/pink metallic dust
    vec3 nebulaColor1 = metalSpectrum(nebulaMix + time_f * 0.1) * vec3(0.8, 0.4, 1.0);
    vec3 nebulaColor2 = metalSpectrum(nebulaMix + time_f * 0.1 + 0.3) * vec3(0.4, 0.6, 1.0);
    vec3 nebulaColor = mix(nebulaColor1, nebulaColor2, swirl * 0.5 + 0.5);

    float gasMask = smoothstep(0.3, 0.6, nebulaMix);
    vec3 finalColor = mix(baseTex, baseTex * 0.5 + nebulaColor, gasMask * (0.4 + hiMid * 0.4));

    // Star particles
    float starField = pow(hash(floor(uv * 40.0)), 20.0);
    float twinkle = sin(time_f * 3.0 + hash(floor(uv * 40.0)) * 100.0) * 0.5 + 0.5;
    finalColor += vec3(1.0, 0.95, 0.9) * starField * twinkle * (2.0 + air * 3.0);

    // Central core glow (newborn star)
    float center = exp(-r * (4.0 - amp_smooth * 2.5));
    finalColor += vec3(1.0, 0.9, 0.95) * center * (2.0 + amp_peak * 3.0);

    // Ripple underlay
    float ripple = sin(r * 12.0 - time_f * 2.0) * (0.03 + bass * 0.04);
    finalColor += ripple * (0.5 + bass);

    color = vec4(finalColor, 1.0);
}
