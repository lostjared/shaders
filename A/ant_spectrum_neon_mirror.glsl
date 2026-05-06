#version 330 core
// ant_spectrum_neon_mirror
// Neon line fractal with mirror box, echo streaks, and rainbow neon glow

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
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 uv0 = uv;

    // Mirror box: abs folds
    uv = abs(uv);
    if (uv.y > uv.x)
        uv = uv.yx;
    uv = abs(uv);

    // Neon fractal
    vec3 neon = vec3(0.0);
    vec2 p = uv;
    for (float i = 0.0; i < 6.0; i++) {
        p = fract(p * (1.4 + mid * 0.3)) - 0.5;
        p = abs(p);
        p *= rot(iTime * 0.08 + i * 0.5);

        float d = length(p);
        d = sin(d * (10.0 + hiMid * 8.0) + iTime) / 10.0;
        d = abs(d);
        float glow = pow(0.01 / max(d, 0.0001), 1.2);
        glow = min(glow, 5.0);

        neon += rainbow(i * 0.16 + length(uv0) + iTime * 0.25 + treble) * glow;
    }

    // Mirror texture
    vec2 texUV = mirror(uv * 0.5 + 0.5);
    vec3 tex = texture(samp, texUV).rgb;

    // Echo streaks
    vec3 echo = vec3(0.0);
    for (float e = 1.0; e < 4.0; e++) {
        float freq = texture(spectrum, e * 0.1 + 0.05).r;
        vec2 eUV = abs(uv0 * (1.0 + e * 0.05));
        if (eUV.y > eUV.x)
            eUV = eUV.yx;
        eUV = abs(eUV);
        vec3 s = texture(samp, mirror(eUV * 0.5 + 0.5)).rgb;
        s *= rainbow(e * 0.25 + freq + iTime * 0.2);
        echo += s * (0.3 / e);
    }

    // Compose
    vec3 result = mix(tex + echo * 0.5, neon * 0.15, 0.4 + bass * 0.2);
    result += tex * 0.5;

    // Rainbow gradient
    float r = length(uv0);
    result *= mix(vec3(1.0), rainbow(r + iTime * 0.3), 0.2 + air * 0.15);

    // Color shift
    result = mix(result, result.brg, smoothstep(0.3, 0.7, sin(iTime * 0.6)));

    result *= 0.85 + amp_smooth * 0.3;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
