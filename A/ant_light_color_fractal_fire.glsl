#version 330 core
// ant_light_color_fractal_fire
// Fractal fire towers with rising ember chains and turbulent color mix

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 fire(float t) {
    vec3 a = vec3(0.5, 0.2, 0.05);
    vec3 b = vec3(0.5, 0.3, 0.1);
    vec3 c = vec3(1.0, 0.7, 0.3);
    vec3 d = vec3(0.0, 0.15, 0.2);
    return a + b * cos(TAU * (c * t + d));
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

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);

    // Fractal fire tower iterations
    vec2 z = p * 3.0;
    z.y -= iTime * (0.5 + bass);

    float fireField = 0.0;
    for (int i = 0; i < 6; i++) {
        z = abs(z) - vec2(0.3, 0.4);
        z = rot(0.5 + float(i) * 0.3 + mid * 0.2) * z;
        z *= 1.2;

        // Turbulence noise injection
        float turb = noise(z * 2.0 + iTime * 0.5) * 0.2;
        z += turb;

        float d = length(z);
        fireField += exp(-d * (1.5 + treble));
    }

    // Texture through fire warp
    vec2 sampUV = tc + vec2(0.0, fireField * 0.01);
    float chroma = treble * 0.03 + fireField * 0.005;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Fire color overlay
    col *= fire(fireField * 0.1 + iTime * 0.05 + bass) * 1.5;

    // Rising embers
    for (float i = 0.0; i < 8.0; i++) {
        float ex = (hash(vec2(i, 1.0)) - 0.5) * aspect;
        float ey = fract(-iTime * (0.5 + hash(vec2(i, 2.0))) + hash(vec2(i, 3.0))) - 0.5;
        float wobble = sin(iTime * 3.0 + i * 2.0) * 0.02;
        vec2 ep = vec2(ex + wobble, ey);
        float d = length(p - ep);
        float glow = 0.001 / (d * d + 0.0003);
        col += fire(i * 0.12 + iTime * 0.15) * glow * (0.05 + bass * 0.1);
    }

    // Base heat
    float baseHeat = smoothstep(0.0, 0.5, 0.5 + p.y) * (0.3 + bass * 0.5);
    col += fire(0.2) * baseHeat * 0.3;

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
