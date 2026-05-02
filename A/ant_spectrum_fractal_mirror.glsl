#version 330 core
// ant_spectrum_fractal_mirror
// Escape-time fractal with mirrored sampling, rainbow palette, and spectrum echoes

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
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.60).r;

    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= iResolution.x / iResolution.y;

    // Mirror the space
    uv = abs(uv);

    // Escape-time fractal
    vec2 p = uv;
    vec2 c = vec2(0.7 + bass * 0.3, 0.4 + mid * 0.3 + sin(iTime * 0.3) * 0.1);
    float iters = 0.0;
    for (float i = 0.0; i < 36.0; i++) {
        p = abs(p) / dot(p, p) - c;
        p *= rot(0.02 * (1.0 + hiMid));
        if (length(p) > 15.0)
            break;
        iters++;
    }
    float normIter = iters / 36.0;

    // Mirror-sample texture through fractal coords
    vec2 texUV = mirror(p * 0.02 + tc);

    // Echo layers with color shift
    vec3 result = vec3(0.0);
    for (float e = 0.0; e < 5.0; e++) {
        float freq = texture(spectrum, e * 0.1 + 0.02).r;
        vec2 off = vec2(freq * 0.02 * (e + 1.0), 0.0) * rot(e * 0.8);
        vec3 s = texture(samp, mirror(texUV + off)).rgb;
        s *= rainbow(e * 0.2 + normIter + iTime * 0.3);
        result += s * (1.0 / (1.0 + e * 0.4));
    }
    result /= 2.5;

    // Fractal coloring
    vec3 fracCol = rainbow(normIter * 3.0 + iTime * 0.2 + bass);
    result = mix(result, fracCol, 0.3 + treble * 0.2);

    // Color shift cycle
    result = mix(result, result.gbr, sin(iTime * 0.4) * 0.5 + 0.5);

    // Glow
    result += exp(-length(uv) * 2.0) * rainbow(iTime * 0.5) * 0.2;

    // Peak
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
