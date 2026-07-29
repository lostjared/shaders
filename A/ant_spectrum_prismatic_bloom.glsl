#version 330 core
// ant_spectrum_prismatic_bloom
// Prism-split bloom with kaleidoscopic mirroring, echo halos, and rainbow dispersion

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

void main() {
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Kaleidoscope
    float seg = floor(8.0 + bass * 6.0);
    vec2 kUV = kaleidoscope(uv, seg);
    kUV = abs(kUV);

    vec2 texUV = mirror(kUV * 0.6 + 0.5);

    // Prismatic dispersion: wide chromatic split
    float dispAngle = atan(uv.y, uv.x);
    float spread = 0.02 + treble * 0.06;
    vec3 prism;
    prism.r = texture(samp, mirror(texUV + vec2(cos(dispAngle), sin(dispAngle)) * spread)).r;
    prism.g = texture(samp, texUV).g;
    prism.b = texture(samp, mirror(texUV - vec2(cos(dispAngle), sin(dispAngle)) * spread)).b;

    // Bloom: radial blur echoes
    vec3 bloom = vec3(0.0);
    float r = length(uv);
    for (float i = 1.0; i < 8.0; i++) {
        float bloomAngle = i * PI * 2.0 / 7.0 + iTime * 0.15;
        float bloomDist = i * (0.005 + mid * 0.01);
        vec2 bUV = kaleidoscope(uv + vec2(cos(bloomAngle), sin(bloomAngle)) * bloomDist, seg);
        bUV = abs(bUV);
        vec3 s = texture(samp, mirror(bUV * 0.6 + 0.5)).rgb;
        s *= rainbow(i * 0.13 + r + iTime * 0.2);
        bloom += s * (1.0 / (1.0 + i * 0.3));
    }
    bloom /= 3.5;

    vec3 result = mix(prism, bloom, 0.4 + hiMid * 0.2);

    // Rainbow gradient
    result *= mix(vec3(1.0), rainbow(r * 2.5 + iTime * 0.4 + bass), 0.3 + air * 0.15);

    // Color shift
    result = mix(result, result.gbr, sin(iTime * 0.5) * 0.4 + 0.4);

    result *= 0.9 + amp_smooth * 0.25;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
