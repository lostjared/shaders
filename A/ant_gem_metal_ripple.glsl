#version 330 core
// ant_gem_metal_ripple
// Liquid metal ripples with mercury-like surface tension and spectrum waves

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

    // Multiple ripple sources
    vec2 src1 = vec2(sin(time_f * 0.7) * 0.3, cos(time_f * 0.5) * 0.2);
    vec2 src2 = vec2(-sin(time_f * 0.6) * 0.25, -cos(time_f * 0.8) * 0.3);
    vec2 src3 = vec2(0.0);

    float d1 = length(uv - src1);
    float d2 = length(uv - src2);
    float d3 = length(uv - src3);

    // Ripple waves from each source, bass drives intensity
    float wave1 = sin(d1 * (20.0 + bass * 15.0) - time_f * 5.0) / (1.0 + d1 * 3.0);
    float wave2 = sin(d2 * (18.0 + mid * 12.0) - time_f * 4.0) / (1.0 + d2 * 3.0);
    float wave3 = sin(d3 * (22.0 + treble * 10.0) - time_f * 6.0) / (1.0 + d3 * 3.0);

    float ripple = wave1 + wave2 + wave3;

    // Surface tension: smooth, mercury-like appearance
    float surface = ripple * (0.5 + bass * 0.5);

    // Normal from ripple for fake reflection
    vec2 dx = vec2(0.01, 0.0);
    vec2 dy = vec2(0.0, 0.01);
    float h = surface;
    float hx = sin((length(uv + dx - src1) * (20.0 + bass * 15.0) - time_f * 5.0)) / (1.0 + length(uv + dx - src1) * 3.0) + sin((length(uv + dx - src2) * (18.0 + mid * 12.0) - time_f * 4.0)) / (1.0 + length(uv + dx - src2) * 3.0);
    float hy = sin((length(uv + dy - src1) * (20.0 + bass * 15.0) - time_f * 5.0)) / (1.0 + length(uv + dy - src1) * 3.0) + sin((length(uv + dy - src2) * (18.0 + mid * 12.0) - time_f * 4.0)) / (1.0 + length(uv + dy - src2) * 3.0);

    vec2 normal = vec2(hx - h, hy - h) * (3.0 + mid * 5.0);

    // Refract texture through liquid metal
    vec2 sampUV = tc + normal * 0.02;

    // Chromatic split for metallic refraction
    float chroma = 0.01 + air * 0.025;
    vec3 baseTex;
    baseTex.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    baseTex.g = texture(samp, sampUV).g;
    baseTex.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Mercury metallic tint: desaturate + silver
    float luma = dot(baseTex, vec3(0.299, 0.587, 0.114));
    vec3 mercury = mix(vec3(luma) * vec3(0.9, 0.92, 0.95), baseTex, 0.4);

    // Rainbow on ripple crests
    float crest = smoothstep(0.3, 0.6, surface);
    vec3 rainbow = metalSpectrum(surface * 2.0 + time_f * 0.2 + r);
    mercury = mix(mercury, mercury * rainbow, crest * (0.4 + hiMid * 0.4));

    // Central glow
    float center = exp(-r * (5.0 - amp_smooth * 3.0));
    mercury += vec3(0.95, 0.97, 1.0) * center * (1.5 + amp_peak * 2.0);

    // Ripple highlights
    mercury += surface * surface * (1.0 + bass * 2.0) * 0.3;

    color = vec4(mercury, 1.0);
}
