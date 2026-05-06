#version 330 core
// ant_light_color_cosmic_ripple
// Concentric cosmic ripples with spectrum-driven interference and color phasing

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 cosmic(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(2.0, 1.0, 0.0);
    vec3 d = vec3(0.5, 0.2, 0.25);
    return a + b * cos(TAU * (c * t + d));
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Multi-source ripples
    float ripple1 = sin(r * 25.0 - iTime * 4.0 + bass * 10.0);
    float ripple2 = sin(r * 18.0 + iTime * 3.0 - mid * 8.0);
    float ripple3 = sin(length(uv - vec2(0.2, 0.1)) * 20.0 - iTime * 5.0);
    float combined = (ripple1 + ripple2 + ripple3) / 3.0;

    // Ripple-driven UV distortion
    vec2 distort = uv + normalize(uv + 0.001) * combined * 0.03 * (1.0 + bass);
    vec2 sampUV = distort * 0.5 + 0.5;

    float chroma = abs(combined) * 0.03 + treble * 0.02;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Interference pattern coloring
    float interference = combined * 0.5 + 0.5;
    col = mix(col, col * cosmic(interference + iTime * 0.1), 0.3 + hiMid * 0.4);

    // Radial color phase
    col *= cosmic(r * 2.0 - iTime * 0.3 + angle / TAU);

    // Bright ripple peaks
    float peak = pow(max(combined, 0.0), 4.0);
    col += cosmic(r + iTime * 0.2) * peak * (0.5 + air * 1.5);

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
