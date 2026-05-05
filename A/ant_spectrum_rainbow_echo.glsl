#version 330 core
// ant_spectrum_rainbow_echo
// Rainbow echo chamber with bi-mirror symmetry, chromatic delay, and gradient fill

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

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.55).r;
    float air    = texture(spectrum, 0.80).r;

    vec2 uv = tc;
    vec2 centered = uv - 0.5;

    // Bi-mirror: flip on both axes + diagonal
    centered = abs(centered);
    centered *= rot(PI / 4.0 + sin(iTime * 0.2) * 0.1);
    centered = abs(centered);
    centered *= rot(-PI / 4.0);
    centered = abs(centered);

    float dist = length(centered);

    // Rainbow echo chamber: multiple delay taps
    vec3 result = vec3(0.0);
    float totalW = 0.0;
    for (float i = 0.0; i < 8.0; i++) {
        // Each echo delays in different direction
        float echoAngle = i * PI * 2.0 / 8.0 + iTime * 0.3;
        float echoDelay = i * (0.01 + mid * 0.01);
        vec2 echoOffset = vec2(cos(echoAngle), sin(echoAngle)) * echoDelay;

        vec2 echoCentered = centered + echoOffset;
        echoCentered = abs(echoCentered);

        vec2 echoTexUV = mirror(echoCentered + 0.5);

        // Chromatic delay: slight channel offset per echo
        float chromDelay = i * 0.002 * (1.0 + treble);
        vec3 s;
        s.r = texture(samp, mirror(echoCentered + 0.5 + vec2(chromDelay, 0.0))).r;
        s.g = texture(samp, echoTexUV).g;
        s.b = texture(samp, mirror(echoCentered + 0.5 - vec2(chromDelay, 0.0))).b;

        // Rainbow per echo tap
        s *= rainbow(i * 0.12 + dist + iTime * 0.2 + bass);

        float w = 1.0 / (1.0 + i * 0.3);
        result += s * w;
        totalW += w;
    }
    result /= totalW;

    // Gradient fill
    vec3 grad = rainbow(dist * 4.0 + iTime * 0.5 + hiMid);
    float gradMask = smoothstep(0.0, 0.4, dist);
    result = mix(result, result * grad, 0.3 * gradMask + air * 0.15);

    // Color cycling
    result = mix(result, result.gbr, sin(iTime * 0.6) * 0.4 + 0.4);

    result *= 0.9 + amp_smooth * 0.25;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
