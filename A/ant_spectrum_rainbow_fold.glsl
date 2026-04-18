#version 330 core
// ant_spectrum_rainbow_fold
// Multi-fold mirror pattern with rainbow color mapping, echo trails, and shifting hues

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

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

void main() {
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.78).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Multi-fold: progressive mirror folds
    vec2 p = uv;
    float foldCount = 0.0;
    for (int i = 0; i < 7; i++) {
        p = abs(p) - 0.2 - float(i) * 0.03;
        p *= rot(PI / (5.0 + bass * 3.0) + float(i) * 0.15);
        p = abs(p);
        foldCount += 1.0;
    }

    // Mirror texture mapping
    vec2 texUV = mirror(p * 0.6 + 0.5);

    // Rainbow color map based on fold depth and position
    float foldVal = length(p);
    vec3 rainbowMap = rainbow(foldVal * 2.0 + foldCount * 0.1 + iTime * 0.3 + bass);

    vec3 tex = texture(samp, texUV).rgb;
    tex *= rainbowMap;

    // Echo trails through fold space
    vec3 echo = vec3(0.0);
    for (float e = 1.0; e < 5.0; e++) {
        vec2 ep = uv;
        for (int i = 0; i < 7; i++) {
            ep = abs(ep) - 0.2 - float(i) * 0.03 + e * 0.005;
            ep *= rot(PI / (5.0 + bass * 3.0) + float(i) * 0.15 + e * 0.02);
            ep = abs(ep);
        }
        vec3 s = texture(samp, mirror(ep * 0.6 + 0.5)).rgb;
        s *= rainbow(e * 0.2 + length(ep) + iTime * 0.2 + mid);
        echo += s * (0.3 / e);
    }

    vec3 result = tex + echo;

    // Hue shifting
    float shift = sin(iTime * 0.7 + hiMid * PI) * 0.5 + 0.5;
    result = mix(result, result.gbr, shift * 0.5);

    // Gradient overlay
    float dist = length(uv);
    result *= mix(vec3(1.0), rainbow(dist + iTime * 0.25), 0.2 + air * 0.15);

    result *= 0.9 + amp_smooth * 0.25;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
