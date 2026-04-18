#version 330 core
// ant_spectrum_mirror_bloom
// Blooming double mirror with spectrum-driven color wash and echo glow

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
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.36).r;
    float treble = texture(spectrum, 0.60).r;
    float air    = texture(spectrum, 0.82).r;

    vec2 uv = tc;
    vec2 centered = uv - 0.5;

    // Double axis mirror with bass wobble
    float wobbleX = bass * sin(centered.y * PI * 2.0 + iTime * 1.5);
    float wobbleY = mid * sin(centered.x * PI * 2.0 + iTime * 1.2);
    centered.x = abs(centered.x + wobbleX * 0.15);
    centered.y = abs(centered.y + wobbleY * 0.15);
    uv = centered + 0.5;

    // Bloom: sample with radial offsets
    vec3 bloom = vec3(0.0);
    float bloomSize = 0.01 + hiMid * 0.03;
    for (float i = 0.0; i < 8.0; i++) {
        float ang = i * PI * 2.0 / 8.0 + iTime * 0.3;
        vec2 off = vec2(cos(ang), sin(ang)) * bloomSize * (1.0 + i * 0.2);
        bloom += texture(samp, mirror(uv + off)).rgb;
    }
    bloom /= 8.0;

    vec3 sharp = texture(samp, mirror(uv)).rgb;
    vec3 result = mix(sharp, bloom, 0.4 + treble * 0.3);

    // Echo trails with color shifting
    for (float e = 1.0; e < 6.0; e++) {
        vec2 echoOff = vec2(sin(iTime * 0.3 + e * 1.1), cos(iTime * 0.4 + e * 0.9)) * e * 0.02;
        vec3 echoSamp = texture(samp, mirror(uv + echoOff)).rgb;
        // Shift hue per echo layer
        echoSamp = mix(echoSamp, echoSamp.gbr, fract(e * 0.3));
        result += echoSamp * (0.15 / e);
    }

    // Rainbow wash
    float dist = length(centered);
    vec3 grad = rainbow(dist * 3.0 + iTime * 0.5 + bass * 2.0);
    result *= mix(vec3(1.0), grad, 0.35 + air * 0.2);

    // Spectrum glow tint
    result += vec3(bass, mid, treble) * 0.15;

    // Peak inversion
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
