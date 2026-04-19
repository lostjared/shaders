#version 330 core
// ant_gem_metal_flux
// Magnetic flux field lines with metallic sheen and spectrum-driven field intensity

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
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Two magnetic poles
    vec2 pole1 = vec2(-0.3 + sin(time_f * 0.5) * 0.1, 0.0);
    vec2 pole2 = vec2(0.3 - sin(time_f * 0.5) * 0.1, 0.0);
    float d1 = length(uv - pole1);
    float d2 = length(uv - pole2);

    // Field lines: angle between poles modulated by spectrum
    float a1 = atan(uv.y - pole1.y, uv.x - pole1.x);
    float a2 = atan(uv.y - pole2.y, uv.x - pole2.x);
    float field = sin((a1 - a2) * (5.0 + bass * 8.0) + time_f * 2.0);
    float fieldLines = smoothstep(0.0, 0.1, abs(field)) * 0.7;
    fieldLines = 1.0 - fieldLines;

    // Radial flux intensity driven by mid
    float flux = sin(d1 * (12.0 + mid * 10.0) - time_f * 3.0) *
                 sin(d2 * (12.0 + mid * 10.0) + time_f * 3.0);

    // Texture warp along field
    vec2 fieldDir = normalize(uv - pole1) * d2 - normalize(uv - pole2) * d1;
    vec2 warpedTC = tc + fieldDir * (0.01 + treble * 0.02);

    // Chromatic split
    float chroma = 0.008 + air * 0.02;
    vec3 baseTex;
    baseTex.r = texture(samp, warpedTC + vec2(chroma, 0.0)).r;
    baseTex.g = texture(samp, warpedTC).g;
    baseTex.b = texture(samp, warpedTC - vec2(chroma, 0.0)).b;

    // Metallic field coloring
    vec3 fieldColor = metalSpectrum(field * 0.3 + time_f * 0.15 + r);
    vec3 finalColor = mix(baseTex, baseTex * fieldColor, fieldLines * (0.5 + hiMid * 0.4));

    // Flux glow on field lines
    finalColor += fieldColor * fieldLines * flux * (0.3 + bass * 0.5);

    // Pole glows
    float poleGlow1 = exp(-d1 * (6.0 - amp_smooth * 3.0));
    float poleGlow2 = exp(-d2 * (6.0 - amp_smooth * 3.0));
    float brightness = 1.5 + amp_peak * 2.0;
    finalColor += vec3(1.0, 0.8, 0.6) * poleGlow1 * brightness;
    finalColor += vec3(0.6, 0.8, 1.0) * poleGlow2 * brightness;

    color = vec4(finalColor, 1.0);
}
