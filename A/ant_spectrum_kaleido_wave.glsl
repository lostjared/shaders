#version 330 core
// ant_spectrum_kaleido_wave
// Wave-distorted kaleidoscope with mirror ocean, echo ripples, and gradient foam

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

vec2 kaleidoscope(vec2 p, float seg) {
    float ang = atan(p.y, p.x);
    float r = length(p);
    float s = 2.0 * PI / seg;
    ang = mod(ang, s);
    ang = abs(ang - s * 0.5);
    return vec2(cos(ang), sin(ang)) * r;
}

vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

void main() {
    float bass = texture(spectrum, 0.04).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Wave distortion before kaleidoscope
    float waveFreq = 4.0 + mid * 6.0;
    float waveAmp = 0.05 + bass * 0.08;
    uv.x += sin(uv.y * waveFreq + iTime * 2.0) * waveAmp;
    uv.y += cos(uv.x * waveFreq * 0.8 + iTime * 1.5) * waveAmp * 0.7;

    // Kaleidoscope
    float seg = floor(6.0 + bass * 6.0);
    vec2 kUV = kaleidoscope(uv, seg);
    kUV = abs(kUV);
    if (kUV.y > kUV.x)
        kUV = kUV.yx;

    // Mirror-wrapped texture
    vec2 texUV = mirror(kUV * 0.7 + 0.5);

    // Echo ripples
    vec3 result = vec3(0.0);
    float r = length(uv);
    for (float e = 0.0; e < 6.0; e++) {
        float ripple = sin(r * (15.0 + hiMid * 10.0) - iTime * 3.0 + e * 1.0);
        float rippleOff = ripple * 0.01 * (e + 1.0);
        vec2 eUV = kaleidoscope(uv + normalize(uv + 0.001) * rippleOff, seg);
        eUV = abs(eUV);
        if (eUV.y > eUV.x)
            eUV = eUV.yx;

        vec3 s = texture(samp, mirror(eUV * 0.7 + 0.5)).rgb;
        s *= rainbow(e * 0.15 + r + iTime * 0.25);
        result += s * (1.0 / (1.0 + e * 0.35));
    }
    result /= 2.8;

    // Foam glow on wave peaks
    float foam = smoothstep(0.5, 1.0, sin(r * waveFreq * 2.0 - iTime * 4.0));
    result += foam * rainbow(r + iTime * 0.4) * 0.15 * (1.0 + treble);

    // Gradient
    result *= mix(vec3(1.0), rainbow(r * 2.0 + iTime * 0.3), 0.25 + air * 0.15);

    // Color shift
    result = mix(result, result.gbr, sin(iTime * 0.6) * 0.3 + 0.3);

    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(result, 1.0);
}
