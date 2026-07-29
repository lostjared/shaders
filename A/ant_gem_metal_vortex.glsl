#version 330 core
// ant_gem_metal_vortex
// Metallic vortex funnel with spectrum-driven spin speed and depth

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
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Vortex twist: angle offset increases toward center
    float spinSpeed = 3.0 + bass * 5.0;
    float twistAmount = (1.0 / (r + 0.1)) * (0.5 + mid * 0.5);
    float vortexAngle = angle + twistAmount - time_f * spinSpeed;

    // Spiral arms
    float arms = sin(vortexAngle * (4.0 + treble * 4.0)) * 0.5 + 0.5;
    arms = pow(arms, 2.0);

    // Depth: radial zoom into vortex center
    float depth = log(r + 0.1) * 2.0 + time_f * 2.0;
    float depthRing = sin(depth * (8.0 + mid * 6.0)) * 0.5 + 0.5;

    // Map vortex coords to texture
    vec2 vortexUV = vec2(cos(vortexAngle), sin(vortexAngle)) * r;
    vortexUV = rot(time_f * 0.3) * vortexUV;
    vec2 sampUV = vortexUV * 0.5 + 0.5;

    // Chromatic split driven by funnel depth
    float chroma = 0.008 + air * 0.02 + (1.0 / (r + 0.3)) * 0.005;
    vec3 baseTex;
    baseTex.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    baseTex.g = texture(samp, sampUV).g;
    baseTex.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Metallic spiral arm coloring
    vec3 armColor = metalSpectrum(vortexAngle * 0.3 + depth * 0.2 + time_f * 0.15);
    vec3 finalColor = mix(baseTex, baseTex * armColor, arms * (0.4 + hiMid * 0.4));

    // Depth ring highlights
    finalColor += metalSpectrum(depth + time_f * 0.2) * depthRing * arms * (0.2 + bass * 0.4);

    // Vortex core glow: intensifies at center
    float coreGlow = exp(-r * (3.0 - amp_smooth * 2.0));
    finalColor += vec3(1.0, 0.95, 0.9) * coreGlow * (2.0 + amp_peak * 3.0);

    // Edge darkening (funnel depth)
    finalColor *= smoothstep(1.5, 0.3, r);

    // Arm sparkle on air
    float sparkle = pow(arms * depthRing, 3.0);
    finalColor += metalSpectrum(time_f * 0.3 + r * 3.0) * sparkle * air * 1.5;

    color = vec4(finalColor, 1.0);
}
