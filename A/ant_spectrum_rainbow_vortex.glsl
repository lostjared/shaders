#version 330 core
// ant_spectrum_rainbow_vortex
// Spiraling rainbow vortex with mirror folds, chromatic echo, and spectrum pulse

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float lowMid = texture(spectrum, 0.10).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Vortex twist: bass drives rotation, exponential falloff
    float twist = (3.0 + bass * 8.0) * exp(-r * 1.5);
    angle += twist + iTime * 0.5;

    // Mirror fold in polar space
    angle = abs(mod(angle, PI / 3.0) - PI / 6.0);

    vec2 warpedUV = vec2(cos(angle), sin(angle)) * r * 0.5 + 0.5;

    // Chromatic echo with rainbow offsets
    vec3 result = vec3(0.0);
    for (float i = 0.0; i < 6.0; i++) {
        float echoDist = i * (0.008 + treble * 0.012);
        float echoAngle = angle + i * 0.02;
        vec2 echoUV = vec2(cos(echoAngle), sin(echoAngle)) * (r + echoDist) * 0.5 + 0.5;
        vec3 samp_col = texture(samp, mirror(echoUV)).rgb;
        samp_col *= rainbow(i * 0.15 + r + iTime * 0.4);
        result += samp_col * (1.0 / (1.0 + i * 0.4));
    }
    result /= 2.5;

    // Spiral arm pattern
    float spiralArms = 5.0 + mid * 3.0;
    float spiral = sin(angle * spiralArms + log(r + 0.001) * 4.0 - iTime * 3.0);
    vec3 spiralColor = rainbow(angle / PI + r + iTime * 0.3);
    result += spiralColor * smoothstep(0.0, 0.8, spiral) * 0.25;

    // Color shift
    result = mix(result, result.gbr, lowMid * 0.6);

    // Vignette with glow
    float glow = exp(-r * (2.5 - bass * 1.5));
    result += glow * rainbow(iTime * 0.6) * 0.3;
    result *= smoothstep(2.0, 0.5, r);

    // Peak
    result = mix(result, vec3(1.0) - result, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
