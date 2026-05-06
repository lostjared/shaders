#version 330 core
// ant_gem_metal_coil
// Metallic spiral coils with bass-pumped tightening and spectrum color bands

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 metalSpectrum(float t) {
    // Replaced the hardcoded number with TAU for mathematical precision
    return vec3(0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67))));
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

    // Spiral coil: angle offset by radius creates spiral arms
    float coilTight = 8.0 + bass * 12.0;
    float spiral = angle + r * coilTight - time_f * 3.0;
    float coil = sin(spiral) * 0.5 + 0.5;
    coil = pow(coil, 4.0 - mid * 2.0); // sharpen coil edges

    // Second coil layer offset
    float spiral2 = angle - r * (coilTight * 0.7) + time_f * 2.0;
    float coil2 = sin(spiral2) * 0.5 + 0.5;
    coil2 = pow(coil2, 3.0);

    // Coil texture warp
    float warp = coil * 0.03 + coil2 * 0.02;
    vec2 sampUV = tc + vec2(warp * cos(angle), warp * sin(angle));

    // Chromatic split on treble
    float chroma = 0.008 + treble * 0.025;
    vec3 baseTex;
    baseTex.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    baseTex.g = texture(samp, sampUV).g;
    baseTex.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // FIX: Divide the spiral by TAU before passing it to the spectrum function.
    // This perfectly cancels out the internal TAU multiplication, maintaining
    // a whole-integer mathematical loop across the angle wrap.
    vec3 coilColor1 = metalSpectrum((spiral / TAU) + time_f * 0.15);
    vec3 coilColor2 = metalSpectrum((spiral2 / TAU) + time_f * 0.2 + 0.5);
    vec3 metalMix = mix(coilColor1, coilColor2, coil2);

    // Blend coils with texture
    float coilMask = max(coil, coil2 * 0.7);
    vec3 finalColor = mix(baseTex, baseTex * metalMix, coilMask * (0.5 + hiMid * 0.4));

    // Central glow
    float lightRadius = 5.0 - amp_smooth * 3.0;
    float center = exp(-r * max(lightRadius, 0.5));
    vec3 coreGlow = vec3(1.0, 0.95, 0.9) * center * (1.5 + amp_peak * 2.0);
    finalColor += coreGlow;

    // Air frequency sparkle on coil edges
    float sparkle = smoothstep(0.4, 0.6, coil) * smoothstep(0.6, 0.4, coil);
    finalColor += sparkle * air * vec3(1.0, 0.95, 0.85) * 2.0;

    color = vec4(finalColor, 1.0);
}