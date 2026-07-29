#version 330 core
// ant_spectrum_kaleidoscope_dream
// Dreamy kaleidoscope with soft echo bloom, rainbow gradient wash, and breathing mirrors

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
    float treble = texture(spectrum, 0.60).r;
    float air    = texture(spectrum, 0.82).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Breathing zoom
    float breath = 1.0 + sin(iTime * 0.8) * 0.1 * amp_smooth;
    uv *= breath;

    // Kaleidoscope with variable segments
    float seg = floor(5.0 + bass * 7.0);
    vec2 kUV = kaleidoscope(uv, seg);

    // Soft dreamy mirror folds
    kUV = abs(kUV);
    kUV = abs(kUV * 1.5 - 0.5);

    // Map to texture
    vec2 texUV = mirror(kUV + 0.5);

    // Dreamy echo bloom: soft radial samples
    vec3 result = vec3(0.0);
    float totalW = 0.0;
    for (float i = 0.0; i < 7.0; i++) {
        float angle = i * PI * 2.0 / 7.0 + iTime * 0.2;
        float dist = (0.005 + mid * 0.015) * (i + 1.0);
        vec2 off = vec2(cos(angle), sin(angle)) * dist;
        vec3 s = texture(samp, mirror(texUV + off)).rgb;
        // Rainbow tint per echo
        s *= rainbow(i * 0.14 + iTime * 0.3 + treble);
        float w = 1.0 / (1.0 + i * 0.3);
        result += s * w;
        totalW += w;
    }
    result /= totalW;

    // Gradient wash
    float r = length(uv);
    float ang = atan(uv.y, uv.x);
    vec3 grad = rainbow(ang / PI * 0.5 + r + iTime * 0.25 + bass);
    result = mix(result, result * grad * 1.4, 0.3 + hiMid * 0.2);

    // Color shifting
    float shift = sin(iTime * 0.6) * 0.5 + 0.5;
    result = mix(result, result.brg, shift * treble);

    // Soft glow
    result += air * 0.1 * vec3(0.5, 0.7, 1.0);

    // Peak inversion
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
