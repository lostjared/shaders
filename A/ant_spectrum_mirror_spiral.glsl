#version 330 core
// ant_spectrum_mirror_spiral
// Spiral mirror tunnel with echo depth, rainbow helix bands, and chromatic trails

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
    float lowMid = texture(spectrum, 0.12).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Spiral: log-polar mapping with mirror
    float spiralFreq = 4.0 + mid * 4.0;
    float spiralAngle = angle + log(r + 0.001) * spiralFreq;
    spiralAngle += iTime * 0.8;

    // Mirror along spiral
    vec2 spiralUV = vec2(
        fract(spiralAngle / (2.0 * PI)),
        fract(r * 3.0 + iTime * 0.3));
    spiralUV = mirror(spiralUV);

    // Additional mirror folds
    vec2 centered = uv;
    centered = abs(centered);
    if (centered.y > centered.x)
        centered = centered.yx;

    // Blend spiral and mirror
    vec2 texUV = mix(spiralUV, mirror(centered + 0.5), 0.3 + bass * 0.2);

    // Chromatic split along spiral
    float spread = 0.01 + treble * 0.03;
    vec3 result;
    result.r = texture(samp, mirror(texUV + vec2(spread, 0.0))).r;
    result.g = texture(samp, texUV).g;
    result.b = texture(samp, mirror(texUV - vec2(spread, 0.0))).b;

    // Echo depth: spiral echoes receding
    for (float e = 1.0; e < 5.0; e++) {
        float eSpiralAngle = angle + log(r + 0.001) * spiralFreq + e * 0.3;
        eSpiralAngle += iTime * 0.8;
        vec2 eUV = vec2(
            fract(eSpiralAngle / (2.0 * PI)),
            fract((r + e * 0.05) * 3.0 + iTime * 0.3));
        eUV = mirror(eUV);
        vec3 s = texture(samp, eUV).rgb;
        s *= rainbow(e * 0.2 + r * 2.0 + iTime * 0.2 + lowMid);
        result += s * (0.25 / e);
    }

    // Rainbow helix bands
    float helixBand = sin(spiralAngle * 3.0 + iTime) * 0.5 + 0.5;
    result = mix(result, result * rainbow(spiralAngle / PI + iTime * 0.3) * 1.4, 0.25 * helixBand + hiMid * 0.15);

    // Color shift
    result = mix(result, result.gbr, air * 0.4);

    result *= 0.9 + amp_smooth * 0.25;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
