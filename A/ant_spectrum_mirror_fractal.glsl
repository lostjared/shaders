#version 330 core
// ant_spectrum_mirror_fractal
// Burning Ship-style fractal with mirror boundaries, echo layers, and rainbow mapping

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
    float bass   = texture(spectrum, 0.03).r;
    float lowMid = texture(spectrum, 0.10).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    vec2 uv = (tc - 0.5) * 2.5;
    uv.x *= iResolution.x / iResolution.y;

    // Mirror the input space
    uv = abs(uv);

    // Burning Ship variant: abs before squaring
    vec2 z = uv;
    vec2 c = vec2(-1.5 + bass * 0.4, -0.05 + lowMid * 0.2 + sin(iTime * 0.2) * 0.1);
    float iters = 0.0;
    for (float i = 0.0; i < 40.0; i++) {
        z = abs(z);
        float xNew = z.x * z.x - z.y * z.y + c.x;
        z.y = 2.0 * z.x * z.y + c.y;
        z.x = xNew;
        if (dot(z, z) > 100.0) break;
        iters++;
    }
    float normIter = iters / 40.0;

    // Texture through fractal with mirror wrap
    vec2 fracTexUV = mirror(z * 0.01 + tc);

    // Echo layers
    vec3 result = vec3(0.0);
    for (float e = 0.0; e < 4.0; e++) {
        float freq = texture(spectrum, e * 0.1 + 0.05).r;
        vec2 off = z * 0.005 * (e + 1.0);
        off += vec2(sin(iTime + e), cos(iTime + e)) * 0.01;
        vec3 s = texture(samp, mirror(fracTexUV + off)).rgb;
        s *= rainbow(e * 0.25 + normIter * 2.0 + iTime * 0.2 + freq);
        result += s * (1.0 / (1.0 + e * 0.4));
    }
    result /= 2.2;

    // Fractal rainbow overlay
    vec3 fracCol = rainbow(normIter * 4.0 + iTime * 0.3 + bass);
    result = mix(result, fracCol, 0.3 + mid * 0.2);

    // Color shift
    result = mix(result, result.brg, smoothstep(0.2, 0.6, treble));

    // Air shimmer
    result += air * 0.1 * rainbow(iTime * 0.4 + normIter);

    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(result, 1.0);
}
