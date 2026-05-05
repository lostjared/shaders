#version 330 core
// ant_spectrum_prism_fold
// Recursive prism folds with mirrored refraction, rainbow dispersion, and echo layers

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
    float bass   = texture(spectrum, 0.03).r;
    float lowMid = texture(spectrum, 0.10).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.55).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Prism fold: triangular reflections
    vec2 p = uv;
    for (int i = 0; i < 6; i++) {
        // Triangular fold
        p -= 0.5 * vec2(0.0, 0.577);
        if (p.x + p.y * 0.577 < 0.0)
            p.x = -p.x;
        if (p.x - p.y * 0.577 < 0.0)
            p = vec2(-p.x * 0.5 + p.y * 0.866, -p.x * 0.866 - p.y * 0.5);
        p = abs(p) * (1.1 + bass * 0.15) - 0.25;
        p *= rot(iTime * 0.06 + float(i) * 0.3);
    }

    // Rainbow dispersion: each channel at different refraction angle
    float dispersion = 0.015 + treble * 0.05;
    vec2 baseUV = mirror(p * 0.5 + 0.5);
    vec3 result;
    result.r = texture(samp, mirror(p * 0.5 + 0.5 + vec2(dispersion, dispersion * 0.5))).r;
    result.g = texture(samp, baseUV).g;
    result.b = texture(samp, mirror(p * 0.5 + 0.5 - vec2(dispersion, dispersion * 0.5))).b;

    // Echo prism layers
    for (float e = 1.0; e < 5.0; e++) {
        vec2 ep = uv;
        for (int i = 0; i < 6; i++) {
            ep -= 0.5 * vec2(0.0, 0.577);
            if (ep.x + ep.y * 0.577 < 0.0)
                ep.x = -ep.x;
            if (ep.x - ep.y * 0.577 < 0.0)
                ep = vec2(-ep.x * 0.5 + ep.y * 0.866, -ep.x * 0.866 - ep.y * 0.5);
            ep = abs(ep) * (1.1 + bass * 0.15 + e * 0.01) - 0.25;
            ep *= rot(iTime * 0.06 + float(i) * 0.3 + e * 0.03);
        }
        vec3 echoCol = texture(samp, mirror(ep * 0.5 + 0.5)).rgb;
        echoCol *= rainbow(e * 0.2 + iTime * 0.3 + lowMid);
        result += echoCol * (0.25 / e);
    }

    // Rainbow gradient
    float dist = length(uv);
    result *= mix(vec3(1.0), rainbow(dist * 2.0 + iTime * 0.4 + mid), 0.3);

    // Color cycle
    result = mix(result, result.brg, smoothstep(0.3, 0.7, sin(iTime * 0.5)));

    result *= 0.9 + amp_smooth * 0.25;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
