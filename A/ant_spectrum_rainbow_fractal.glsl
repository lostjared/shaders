#version 330 core
// ant_spectrum_rainbow_fractal
// Fractal attractor with mirrored boundaries, rainbow iteration coloring, and echo trails

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
    float lowMid = texture(spectrum, 0.10).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.55).r;
    float air = texture(spectrum, 0.80).r;

    vec2 uv = (tc - 0.5) * 2.5;
    uv.x *= iResolution.x / iResolution.y;

    // Mirror quad
    uv = abs(uv);
    if (uv.y > uv.x)
        uv = uv.yx;

    // Fractal attractor: Sierpinski-like fold
    vec2 p = uv;
    float iters = 0.0;
    vec3 iterColor = vec3(0.0);
    for (float i = 0.0; i < 30.0; i++) {
        p = abs(p);
        if (p.y > p.x)
            p = p.yx;
        p -= vec2(0.5 + bass * 0.2, 0.3 + lowMid * 0.2);
        p *= rot(0.5 + mid * 0.3 + sin(iTime * 0.2) * 0.1);
        p *= 1.1;
        if (length(p) > 10.0)
            break;
        iters++;
        // Accumulate rainbow per iteration
        iterColor += rainbow(i * 0.1 + iTime * 0.1) * 0.03;
    }
    float normIter = iters / 30.0;

    // Mirror-wrapped texture through fractal
    vec2 texUV = mirror(p * 0.01 + tc);

    // Echo trails
    vec3 result = vec3(0.0);
    for (float e = 0.0; e < 4.0; e++) {
        float freq = texture(spectrum, e * 0.1 + 0.05).r;
        vec2 eOff = p * 0.005 * (e + 1.0);
        vec3 s = texture(samp, mirror(texUV + eOff)).rgb;
        s *= rainbow(e * 0.25 + normIter * 3.0 + iTime * 0.2 + freq);
        result += s * (1.0 / (1.0 + e * 0.4));
    }
    result /= 2.2;

    // Fractal rainbow coloring
    result += iterColor * (0.5 + treble * 0.3);
    vec3 fracCol = rainbow(normIter * 4.0 + iTime * 0.3);
    result = mix(result, fracCol, 0.2 + mid * 0.15);

    // Color shift
    result = mix(result, result.gbr, smoothstep(0.3, 0.6, sin(iTime * 0.7)));

    result += air * 0.06 * rainbow(iTime + normIter);
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
