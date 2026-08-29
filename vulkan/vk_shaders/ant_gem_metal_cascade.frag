#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define time_f ext.u2.y

// ant_gem_metal_cascade
// Cascading metallic waterfalls with spectrum-driven flow speed and gem facets
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;




layout(set = 0, binding = 3) uniform sampler1D spectrum;

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

    // Cascade: multiple falling wave layers
    float cascade = 0.0;
    for (float i = 1.0; i < 6.0; i++) {
        float speed = time_f * (2.0 + i * 0.8 + bass * 3.0);
        float freq = 8.0 + i * 4.0 + mid * 6.0;
        float wave = sin(uv.y * freq - speed + uv.x * i * 2.0);
        cascade += wave * (0.2 / i);
    }

    // Horizontal metallic bands react to treble
    float bands = sin(uv.y * (30.0 + treble * 20.0) - time_f * 5.0) * 0.5 + 0.5;
    bands = pow(bands, 3.0);

    // Gem facet distortion
    float facetAngle = floor(angle * 3.0 + 0.5) / 3.0;
    float facetBlend = smoothstep(0.0, 0.02, abs(angle - facetAngle));
    float facetShift = cascade * 0.02 * (1.0 - facetBlend);

    // Chromatic split tied to air frequencies
    float shift = facetShift + air * 0.012;
    vec3 baseTex;
    baseTex.r = texture(samp, tc + vec2(shift, cascade * 0.01)).r;
    baseTex.g = texture(samp, tc + vec2(0.0, cascade * 0.005)).g;
    baseTex.b = texture(samp, tc - vec2(shift, cascade * 0.01)).b;

    // Metallic waterfall highlight
    vec3 metalColor = metalSpectrum(cascade + time_f * 0.15 + r);
    float highlight = bands * (0.4 + hiMid * 0.5);

    // Central glow
    float lightRadius = 5.0 - amp_smooth * 3.0;
    float center = exp(-r * max(lightRadius, 0.5));
    vec3 coreGlow = vec3(0.95, 0.9, 1.0) * center * (1.3 + amp_peak * 1.8);

    vec3 finalColor = baseTex;
    finalColor = mix(finalColor, metalColor, highlight);
    finalColor += coreGlow;
    finalColor += cascade * bands * (1.5 + bass * 2.0);

    color = vec4(finalColor, 1.0);
}
