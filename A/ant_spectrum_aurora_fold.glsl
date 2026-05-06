#version 330 core
// ant_spectrum_aurora_fold
// Aurora borealis curtains with mirror folds, rainbow bands, and echo streaks

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 aurora(float t) {
    vec3 a = vec3(0.2, 0.5, 0.3);
    vec3 b = vec3(0.3, 0.5, 0.4);
    vec3 c = vec3(1.0, 1.0, 1.5);
    vec3 d = vec3(0.0, 0.15, 0.4);
    return a + b * cos(6.28318 * (c * t + d));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.20).r;
    float hiMid = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    vec2 uv = tc;
    vec2 centered = uv - 0.5;

    // Horizontal mirror fold
    centered.x = abs(centered.x);
    // Vertical fold with bass wobble
    centered.y = abs(centered.y + bass * 0.1 * sin(centered.x * PI * 4.0 + iTime));

    // Aurora curtain distortion
    float curtainFreq = 3.0 + mid * 5.0;
    float curtain = noise(vec2(centered.x * curtainFreq, iTime * 0.5)) * 0.08;
    centered.y += curtain * (1.0 + hiMid);

    uv = centered + 0.5;

    // Mirror-wrapped texture sample
    vec3 tex = texture(samp, mirror(uv)).rgb;

    // Aurora streaks: echo layers
    vec3 auroraGlow = vec3(0.0);
    for (float i = 0.0; i < 6.0; i++) {
        float yOff = i * 0.03 + noise(vec2(centered.x * 8.0 + i, iTime * 0.3 + i)) * 0.05;
        float streak = exp(-pow((centered.y - yOff - 0.1) * 10.0, 2.0));
        float freq = texture(spectrum, i * 0.1 + 0.02).r;
        auroraGlow += aurora(i * 0.15 + iTime * 0.2 + freq) * streak * (1.0 + freq);
    }

    vec3 result = tex + auroraGlow * (0.4 + treble * 0.3);

    // Rainbow gradient
    float grad = centered.y + 0.5;
    result *= mix(vec3(1.0), aurora(grad + iTime * 0.15), 0.25 + air * 0.2);

    // Color shift
    result = mix(result, result.gbr, smoothstep(0.4, 0.8, mid));

    // Brightness
    result *= 0.85 + amp_smooth * 0.3;
    result = mix(result, vec3(1.0) - result, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
