#version 330 core
// ant_spectrum_diamond_echo
// Diamond-fold kaleidoscope with cascading echo reflections and gradient glow

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

vec2 diamondFold(vec2 p) {
    p = abs(p);
    if (p.y > p.x) p = p.yx;
    return p;
}

vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.78).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Multi-pass diamond fold
    vec2 p = uv;
    for (int i = 0; i < 5; i++) {
        p = diamondFold(p);
        p = p * (1.2 + bass * 0.2) - 0.3;
        p *= rot(iTime * 0.08 + float(i) * 0.4 + mid * 0.3);
    }

    // Echo cascade: each echo at different fold depth
    vec3 result = vec3(0.0);
    float totalW = 0.0;
    for (float e = 0.0; e < 6.0; e++) {
        vec2 ep = uv;
        for (int i = 0; i < 5; i++) {
            ep = diamondFold(ep);
            ep = ep * (1.2 + bass * 0.2 + e * 0.02) - 0.3;
            ep *= rot(iTime * 0.08 + float(i) * 0.4 + mid * 0.3 + e * 0.05);
        }
        vec2 texUV = mirror(ep * 0.5 + 0.5);
        vec3 s = texture(samp, texUV).rgb;
        s *= rainbow(e * 0.16 + iTime * 0.3 + hiMid);
        float w = 1.0 / (1.0 + e * 0.5);
        result += s * w;
        totalW += w;
    }
    result /= totalW;

    // Diamond glow pattern
    float dGlow = length(p);
    vec3 grad = rainbow(dGlow + iTime * 0.4 + bass * 2.0);
    result = mix(result, result * grad * 1.3, 0.3 + treble * 0.2);

    // Color shift
    result = mix(result, result.brg, smoothstep(0.3, 0.7, sin(iTime * 0.6)));

    // Air shimmer
    result += air * 0.08 * rainbow(iTime * 0.4 + length(uv));

    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(result, 1.0);
}
