#version 330 core
// ant_spectrum_kaleido_pulse
// Pulsing kaleidoscope with mirrored folds, chromatic echo rings, and gradient pulse

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
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.20).r;
    float hiMid  = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.55).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Pulse zoom
    float pulse = 1.0 + bass * 0.3 * sin(iTime * 4.0);
    uv *= pulse;

    // Kaleidoscope
    float seg = floor(6.0 + mid * 6.0);
    vec2 kUV = kaleidoscope(uv, seg);

    // Mirror fold
    kUV = abs(kUV);

    // Map to texture
    vec2 texUV = mirror(kUV * 0.7 + 0.5);

    // Chromatic echo rings
    float r = length(uv);
    float spread = 0.008 + treble * 0.02;
    vec3 result = vec3(0.0);
    for (float e = 0.0; e < 6.0; e++) {
        float ringOff = e * spread;
        vec2 ringUV = kaleidoscope(uv * (1.0 + ringOff), seg);
        ringUV = abs(ringUV);
        vec2 rTexUV = mirror(ringUV * 0.7 + 0.5);

        vec3 s;
        s.r = texture(samp, mirror(rTexUV + vec2(spread * e * 0.5, 0.0))).r;
        s.g = texture(samp, rTexUV).g;
        s.b = texture(samp, mirror(rTexUV - vec2(spread * e * 0.5, 0.0))).b;

        s *= rainbow(e * 0.15 + r + iTime * 0.3 + hiMid);
        result += s * (1.0 / (1.0 + e * 0.35));
    }
    result /= 2.8;

    // Gradient pulse
    vec3 grad = rainbow(r * 3.0 + iTime * 0.5 + bass * 2.0);
    float pulseGrad = sin(r * 10.0 - iTime * 5.0) * 0.5 + 0.5;
    result = mix(result, result * grad, 0.3 * pulseGrad + air * 0.15);

    // Color shift
    result = mix(result, result.gbr, sin(iTime * 0.8) * 0.4 + 0.4);

    result *= 0.85 + amp_smooth * 0.3;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
