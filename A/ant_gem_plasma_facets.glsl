#version 330 core
// ant_gem_plasma_facets
// Kaleidoscope facets with flowing plasma noise and spectrum gradient tinting

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

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

vec3 specGrad(float t, float intensity) {
    vec3 c1 = vec3(0.1, 0.8, 1.0);
    vec3 c2 = vec3(1.0, 0.1, 0.6);
    vec3 c3 = vec3(0.5, 0.1, 1.0);
    float p = fract(t + intensity);
    vec3 g = mix(c1, c2, smoothstep(0.0, 0.5, p));
    g = mix(g, c3, smoothstep(0.5, 1.0, p));
    return g * (0.5 + intensity * 1.5);
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);

    // Bass zoom breathing
    p *= 1.0 - bass * 0.3;

    // Kaleidoscope facets
    float segments = 6.0 + floor(hiMid * 10.0);
    float angle = atan(p.y, p.x);
    float radius = length(p);
    float step_val = 2.0 * PI / segments;
    angle = mod(angle, step_val);
    angle = abs(angle - step_val * 0.5);
    p = vec2(cos(angle), sin(angle)) * radius;

    // Plasma noise distortion
    float noiseFreq = 4.0 + mid * 4.0;
    float n1 = noise(p * noiseFreq + iTime * 0.5);
    float n2 = noise(p * noiseFreq * 1.5 - iTime * 0.3 + 50.0);
    vec2 plasmaOff = vec2(n1, n2) * 0.07 * (1.0 + bass * 0.5);

    // Map to texture
    vec2 sampUV = p;
    sampUV.x /= aspect;
    sampUV = sampUV + 0.5 + plasmaOff;
    sampUV = clamp(sampUV, 0.0, 1.0);

    // Sample with treble-driven chromatic split
    float chroma = treble * 0.04;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(0.0, chroma)).b;

    // Spectrum gradient tinting
    vec3 tint = specGrad(radius + iTime * 0.2, mid);
    col = mix(col, col * tint, 0.3 + air * 0.25);

    // Plasma edge glow
    float edgeLine = abs(fract(n1 * 3.0 + iTime * 0.5) - 0.5);
    float plasmaGlow = pow(0.005 / max(edgeLine, 0.001), 0.7);
    col += tint * plasmaGlow * 0.08 * (1.0 + treble);

    col *= 0.85 + amp_smooth * 0.35;
    col *= 1.0 + bass * 0.4;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
