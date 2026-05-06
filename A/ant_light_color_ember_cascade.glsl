#version 330 core
// ant_light_color_ember_cascade
// Cascading ember particles over fractal waterfall with warm-to-cool gradient

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 ember(float t) {
    vec3 a = vec3(0.5, 0.15, 0.05);
    vec3 b = vec3(0.5, 0.4, 0.2);
    vec3 c = vec3(1.5, 1.0, 0.6);
    vec3 d = vec3(0.0, 0.1, 0.25);
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
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Waterfall fractal flow
    vec2 flow = uv;
    flow.y += iTime * 0.5;
    float cascade = 0.0;
    vec2 fp = flow * 3.0;
    for (int i = 0; i < 5; i++) {
        fp = abs(fp) - 0.5;
        fp = rot(0.7 + float(i) * 0.3 + bass * 0.2) * fp;
        fp *= 1.3;
        cascade += exp(-length(fp) * (1.0 + treble));
    }

    // Texture through cascade warp
    vec2 warpUV = tc + vec2(0.0, cascade * 0.02);
    float n = noise(uv * 8.0 + iTime);
    warpUV += n * 0.01 * mid;

    float chroma = treble * 0.03;
    vec3 col;
    col.r = texture(samp, warpUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, warpUV).g;
    col.b = texture(samp, warpUV - vec2(chroma, 0.0)).b;

    // Ember warm overlay
    col = mix(col, col * ember(cascade * 0.3 + iTime * 0.05), 0.3 + mid * 0.3);

    // Falling ember particles
    for (float i = 0.0; i < 8.0; i++) {
        vec2 particlePos = vec2(hash(vec2(i, 1.0)) - 0.5, fract(-iTime * (0.3 + hash(vec2(i, 2.0))) + hash(vec2(i, 3.0))) - 0.5);
        particlePos.x *= aspect;
        float d = length(uv - particlePos);
        float glow = 0.003 / (d * d + 0.001);
        col += ember(i * 0.12 + iTime * 0.1) * glow * (0.1 + bass * 0.3);
    }

    // Cool-to-warm gradient based on height
    vec3 coolWarm = mix(ember(0.7), ember(0.1), uv.y + 0.5);
    col *= mix(vec3(1.0), coolWarm, 0.2 + air * 0.3);

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
