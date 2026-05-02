#version 330 core
// ant_spectrum_kaleido_storm
// Turbulent kaleidoscope storm with noise-driven mirrors, echo chaos, and rainbow lightning

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

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
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
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Turbulent noise pre-distortion
    float turbStr = 0.08 + bass * 0.12;
    float n1 = noise(uv * 4.0 + iTime * 0.8);
    float n2 = noise(uv * 4.0 - iTime * 0.6);
    vec2 turbUV = uv + vec2(n1, n2) * turbStr;

    // Kaleidoscope on turbulent coords
    float seg = floor(5.0 + mid * 7.0);
    vec2 kUV = kaleidoscope(turbUV, seg);

    // Mirror fold
    kUV = abs(kUV);
    kUV *= rot(iTime * 0.05);
    kUV = abs(kUV);
    if (kUV.y > kUV.x)
        kUV = kUV.yx;

    // Texture
    vec2 texUV = mirror(kUV * 0.6 + 0.5);
    vec3 tex = texture(samp, texUV).rgb;

    // Echo chaos: turbulent echo layers
    vec3 echo = vec3(0.0);
    for (float e = 1.0; e < 5.0; e++) {
        float en1 = noise(uv * (3.0 + e) + iTime * 0.5 * e);
        float en2 = noise(uv * (3.0 + e) - iTime * 0.4 * e);
        vec2 eUV = kaleidoscope(uv + vec2(en1, en2) * turbStr * e * 0.5, seg);
        eUV = abs(eUV);
        vec3 s = texture(samp, mirror(eUV * 0.6 + 0.5)).rgb;
        s *= rainbow(e * 0.2 + n1 + iTime * 0.2);
        echo += s * (0.3 / e);
    }

    vec3 result = tex + echo;

    // Lightning flashes from noise peaks
    float lightning = pow(noise(uv * 15.0 + iTime * 4.0), 6.0);
    result += lightning * rainbow(iTime * 0.6 + hiMid) * 1.5 * bass;

    // Rainbow gradient
    float r = length(uv);
    result *= mix(vec3(1.0), rainbow(r + iTime * 0.3 + treble), 0.25 + air * 0.15);

    // Color cycle
    result = mix(result, result.brg, sin(iTime * 0.5) * 0.4 + 0.4);

    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(result, 1.0);
}
