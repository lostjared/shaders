#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define iTime ext.u0.y

// ant_gem_nebula_fold
// Fractal fold iterations with nebula color palette and mid-driven fold complexity
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;




layout(set = 0, binding = 3) uniform sampler1D spectrum;

const float PI = 3.14159265;

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

vec3 nebula(float t) {
    vec3 a = vec3(0.3, 0.1, 0.4);
    vec3 b = vec3(0.4, 0.3, 0.5);
    vec3 c = vec3(1.5, 1.0, 1.2);
    vec3 d = vec3(0.1, 0.2, 0.5);
    return a + b * cos(6.28318 * (c * t + d));
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 p0 = p;

    // Bass zoom
    p *= 1.0 - bass * 0.25;

    // Kaleidoscope base
    float seg = floor(6.0 + mid * 6.0);
    float ang = atan(p.y, p.x);
    float rad = length(p);
    float stepA = 2.0 * PI / seg;
    ang = mod(ang, stepA);
    ang = abs(ang - stepA * 0.5);
    p = vec2(cos(ang), sin(ang)) * rad;

    // Fractal fold iterations: complexity driven by mid+hiMid
    int foldCount = 3 + int(mid * 2.0 + hiMid * 2.0);
    float foldZoom = 1.15 + 0.15 * sin(iTime * 0.4) + bass * 0.2;
    vec2 ctr = vec2(0.0);
    for (int i = 0; i < 7; i++) {
        if (i >= foldCount) break;
        p = abs((p - ctr) * (foldZoom + 0.1 * sin(iTime * 0.3 + float(i)))) - 0.4 + ctr;
        p = rot(iTime * 0.1 + float(i) * 0.07 + mid * 0.2) * p;
    }

    // Map to texture
    vec2 sampUV = p;
    sampUV.x /= aspect;
    sampUV = fract(sampUV + 0.5);

    // Chromatic split on treble
    float chroma = treble * 0.04;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Nebula palette overlay: tinted by fold depth
    float foldDepth = length(p - p0 * 2.0) * 0.5;
    vec3 nebCol = nebula(foldDepth + iTime * 0.1 + bass);
    col = mix(col, col * nebCol, 0.35 + air * 0.25);

    // Gas cloud glow at fold intersections
    float foldGlow = pow(0.01 / max(length(fract(p * 3.0) - 0.5), 0.001), 0.6);
    col += nebCol * foldGlow * 0.1 * (1.0 + hiMid);

    // Star sparkle from spectrum
    for (float i = 0.0; i < 4.0; i++) {
        float freq = texture(spectrum, i * 0.12 + 0.05).r;
        float star = step(0.97, fract(sin(dot(floor(p * (8.0 + i * 3.0)), vec2(12.9898, 78.233))) * 43758.5453));
        col += vec3(0.8, 0.7, 1.0) * star * freq * 0.4;
    }

    col *= 0.85 + amp_smooth * 0.35;
    col *= 1.0 + bass * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
