#version 330 core
// ant_spectrum_chromatic_lotus
// Lotus petal kaleidoscope with chromatic separation, echo petals, and rainbow glow

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

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass = texture(spectrum, 0.04).r;
    float lowMid = texture(spectrum, 0.12).r;
    float mid = texture(spectrum, 0.25).r;
    float hiMid = texture(spectrum, 0.42).r;
    float treble = texture(spectrum, 0.60).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 uv0 = uv;

    // Lotus petals: high segment kaleidoscope
    float petals = floor(8.0 + bass * 10.0);
    uv = kaleidoscope(uv, petals);

    // Petal curve fold
    float r = length(uv);
    float petalCurve = sin(r * (6.0 + mid * 8.0) - iTime * 2.0);
    uv += normalize(uv + 0.001) * petalCurve * 0.05;

    // Mirror fold
    uv = abs(uv);

    // Slow rotation
    uv *= rot(iTime * 0.1 + lowMid * 0.5);

    // Map to texture
    vec2 texUV = mirror(uv * 0.6 + 0.5);

    // Chromatic lotus: split R/G/B with petal offsets
    float spread = 0.01 + treble * 0.04;
    vec3 result;
    result.r = texture(samp, mirror(texUV + vec2(spread, 0.0))).r;
    result.g = texture(samp, texUV).g;
    result.b = texture(samp, mirror(texUV - vec2(spread, 0.0))).b;

    // Echo petals
    for (float e = 1.0; e < 4.0; e++) {
        float freq = texture(spectrum, e * 0.09).r;
        vec2 eUV = kaleidoscope(uv0 * (1.0 + e * 0.08), petals);
        eUV = abs(eUV);
        eUV *= rot(iTime * 0.05 * e);
        vec3 echoCol = texture(samp, mirror(eUV * 0.6 + 0.5)).rgb;
        echoCol *= rainbow(e * 0.25 + iTime * 0.2 + freq);
        result += echoCol * (0.25 / e);
    }

    // Rainbow glow from center
    float dist = length(uv0);
    vec3 glow = rainbow(dist * 2.0 + iTime * 0.4 + bass) * exp(-dist * 3.0);
    result += glow * (0.3 + hiMid * 0.3);

    // Color cycling
    float cycle = sin(iTime * 0.5) * 0.5 + 0.5;
    result = mix(result, result.brg, cycle * 0.4);

    // Brightness
    result *= 0.9 + amp_smooth * 0.3;
    result = mix(result, vec3(1.0) - result, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
