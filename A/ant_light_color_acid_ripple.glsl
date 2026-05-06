#version 330 core
// ant_light_color_acid_ripple
// Acid-colored expanding ripples with interference and feedback distortion

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 acid(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 0.5);
    vec3 d = vec3(0.3, 0.2, 0.2);
    return a + b * cos(TAU * (c * t + d));
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Multiple ripple sources
    vec2 src1 = vec2(sin(iTime * 0.3) * 0.2, cos(iTime * 0.4) * 0.15);
    vec2 src2 = vec2(-sin(iTime * 0.5) * 0.15, sin(iTime * 0.3) * 0.2);
    vec2 src3 = vec2(cos(iTime * 0.2) * 0.1, -cos(iTime * 0.6) * 0.1);

    float r1 = length(uv - src1);
    float r2 = length(uv - src2);
    float r3 = length(uv - src3);

    float wave1 = sin(r1 * (20.0 + bass * 15.0) - iTime * 5.0);
    float wave2 = sin(r2 * (18.0 + mid * 12.0) - iTime * 4.0);
    float wave3 = sin(r3 * (22.0 + treble * 10.0) - iTime * 6.0);

    float combined = (wave1 + wave2 + wave3) / 3.0;

    // Feedback-style UV distortion
    vec2 distort = vec2(
        combined * 0.03 * (1.0 + bass),
        (wave1 - wave2) * 0.02 * (1.0 + mid));
    vec2 sampUV = tc + distort;

    float chroma = abs(combined) * 0.04 + treble * 0.02;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Acid color interference
    float interference = combined * 0.5 + 0.5;
    col *= acid(interference + iTime * 0.1 + bass) * 1.5;

    // Bright wave crests
    float crest = pow(max(combined, 0.0), 6.0);
    col += acid(r1 + iTime * 0.2) * crest * (1.0 + air * 2.0);

    // Source point glow
    for (int i = 0; i < 3; i++) {
        vec2 src = (i == 0) ? src1 : (i == 1) ? src2
                                              : src3;
        float glow = exp(-length(uv - src) * (5.0 - bass * 2.0));
        col += acid(float(i) * 0.33 + iTime * 0.3) * glow * (0.5 + amp_peak);
    }

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
