#version 330 core
// ant_gem_metal_orbital
// Orbital metallic rings at varying angles with spectrum-driven tilt and speed

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

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
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

    // Multiple orbital rings at different tilts
    vec3 ringAccum = vec3(0.0);
    for (float i = 0.0; i < 5.0; i++) {
        float tilt = i * 0.628 + time_f * 0.3 * (1.0 + i * 0.2) + bass * 0.5;
        vec2 tilted = rot(tilt) * uv;

        // Perspective compression for 3D-like tilt
        float perspective = 1.0 + tilted.y * (0.3 + mid * 0.2);
        tilted.x *= perspective;

        float ringR = length(tilted);
        float ringDist = abs(ringR - (0.3 + i * 0.08));
        float ringWidth = 0.015 + treble * 0.01;
        float ring = exp(-ringDist * ringDist / (ringWidth * ringWidth));

        vec3 ringColor = metalSpectrum(i * 0.2 + time_f * 0.15 + ringR);
        ringAccum += ringColor * ring * (0.8 + hiMid * 0.5);
    }

    // Texture sampling with orbital warp
    float orbitalWarp = length(ringAccum) * 0.01;
    vec2 sampUV = tc + vec2(cos(angle), sin(angle)) * orbitalWarp;

    // Chromatic split
    float chroma = 0.008 + air * 0.02;
    vec3 baseTex;
    baseTex.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    baseTex.g = texture(samp, sampUV).g;
    baseTex.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    vec3 finalColor = baseTex + ringAccum;

    // Gem ripple underlay
    float ripple = sin(r * (18.0 + mid * 10.0) - time_f * 3.0);
    float rippleMask = smoothstep(0.5, 1.0, ripple);
    vec3 rippleColor = metalSpectrum(r + time_f * 0.2);
    finalColor = mix(finalColor, finalColor * rippleColor, rippleMask * 0.2);

    // Central planet glow
    float center = exp(-r * (6.0 - amp_smooth * 4.0));
    finalColor += vec3(1.0, 0.95, 0.9) * center * (2.0 + amp_peak * 3.0);

    color = vec4(finalColor, 1.0);
}
