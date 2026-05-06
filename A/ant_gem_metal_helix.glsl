#version 330 core
// ant_gem_metal_helix
// Double helix metallic bands with DNA-like twist and spectrum color encoding

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

    // Double helix: two sinusoidal strands along vertical axis
    float twist = 8.0 + bass * 6.0;
    float speed = time_f * 3.0;

    float strand1 = sin(uv.y * twist - speed) * (0.15 + mid * 0.1);
    float strand2 = sin(uv.y * twist - speed + 3.14159) * (0.15 + mid * 0.1);

    // Distance to each strand
    float d1 = abs(uv.x - strand1);
    float d2 = abs(uv.x - strand2);

    float width = 0.04 + treble * 0.03;
    float glow1 = exp(-d1 * d1 / (width * width));
    float glow2 = exp(-d2 * d2 / (width * width));

    // Connecting rungs between strands
    float rungPhase = uv.y * twist - speed;
    float rungInterval = mod(rungPhase, 3.14159);
    float isRung = smoothstep(0.1, 0.0, abs(rungInterval - 1.57));
    float rungX = mix(strand1, strand2, (uv.x - strand1) / max(strand2 - strand1, 0.001));
    float onRung = isRung * step(min(strand1, strand2), uv.x) * step(uv.x, max(strand1, strand2));
    float rungGlow = onRung * 0.5;

    // Warp texture along helix
    float helixWarp = (glow1 + glow2) * 0.03;
    vec2 sampUV = tc + vec2(helixWarp, 0.0);

    // Chromatic split
    float chroma = 0.008 + air * 0.02;
    vec3 baseTex;
    baseTex.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    baseTex.g = texture(samp, sampUV).g;
    baseTex.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Color each strand differently
    vec3 color1 = metalSpectrum(uv.y * 0.5 + time_f * 0.2);
    vec3 color2 = metalSpectrum(uv.y * 0.5 + time_f * 0.2 + 0.5);
    vec3 rungColor = metalSpectrum(rungPhase * 0.1 + time_f * 0.15);

    vec3 helixColor = color1 * glow1 + color2 * glow2 + rungColor * rungGlow;
    helixColor *= 1.5 + hiMid * 2.0;

    vec3 finalColor = baseTex + helixColor;

    // Central glow
    float center = exp(-r * (5.0 - amp_smooth * 3.0));
    finalColor += vec3(1.0, 0.97, 0.92) * center * (1.3 + amp_peak * 1.8);

    // Ripple underlay
    float ripple = sin(r * 15.0 - time_f * 2.0) * 0.5 + 0.5;
    finalColor += metalSpectrum(r + time_f * 0.1) * ripple * 0.1 * bass;

    color = vec4(finalColor, 1.0);
}
