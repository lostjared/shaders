#version 330 core

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

out vec4 color;

// --- Noise & Logic Functions from the complex shader ---

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash(i + vec2(0.0, 0.0));
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p *= 2.1;
        a *= 0.55;
    }
    return v;
}

vec2 kaleido(vec2 p, float slices) {
    float pi = 3.14159265359;
    float r = length(p);
    float a = atan(p.y, p.x);
    float sector = pi * 2.0 / slices;
    a = mod(a, sector);
    a = abs(a - sector * 0.5);
    return vec2(cos(a), sin(a)) * r;
}

// Adapted sampleWarp to use 'samp' and hardcoded amp/freq
vec3 sampleWarp(vec2 uv, float t, float strength, vec2 center, vec2 res) {
    float aspect = res.x / res.y;

    // Hardcoded values since we don't have uniforms for them anymore
    float ampControl = 1.0;
    float freqControl = 1.0;

    vec2 p = (uv - center) * vec2(aspect, 1.0);
    float f1 = fbm(p * 1.8 + t * 0.3);
    float f2 = fbm(p.yx * 2.3 - t * 0.25);
    float f3 = fbm(p * 3.1 + vec2(1.3, -0.7) * t * 0.2);

    vec2 swirl = p;
    float r = length(swirl);
    float a = atan(swirl.y, swirl.x);
    a += (f1 * 4.0 + f2 * 2.0) * strength * 0.6;
    swirl = vec2(cos(a), sin(a)) * r;

    float sliceBase = 8.0;
    float sliceRange = 8.0;
    float slices = sliceBase + sliceRange * (0.3 + 0.7 * ampControl) + 4.0 * sin(t * 0.17);

    vec2 k = kaleido(swirl + vec2(f2, f3) * 0.4 * strength, slices);

    vec2 flow = k;
    flow.x += f1 * 0.8 * strength;
    flow.y += (f2 - f3) * 0.8 * strength;

    vec2 base = flow / vec2(aspect, 1.0) + center;
    base = fract(base);

    float chromaBoost = 0.5 + 0.5 * ampControl;
    vec2 chromaShift = 0.0035 * strength * chromaBoost *
                       vec2(sin(t + f1 * 6.0), cos(t * 1.3 + f2 * 6.0));

    // Using 'samp' here instead of 'textTexture'
    float rC = texture(samp, base + chromaShift).r;
    float gC = texture(samp, base).g;
    float bC = texture(samp, base - chromaShift).b;
    vec3 col = vec3(rC, gC, bC);

    float bright = 0.7 + 0.6 * f3 + 0.4 * sin(t * 0.6 + f1 * 3.0);
    bright *= (0.6 + 0.8 * freqControl);

    col *= bright;

    float sat = 1.3 + 0.7 * sin(t * 0.43 + f2 * 5.0);
    sat *= (0.6 + 0.8 * freqControl);

    float gray = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(gray), col, sat);

    return col;
}

void main() {
    // Calculate UV based on resolution (matching your example)
    vec2 uv = gl_FragCoord.xy / iResolution;

    // Hardcoded control values
    float ampControl = 1.0;
    float freqControl = 1.0;

    float tSpeed = 0.3 + 1.7 * (freqControl * 0.5);
    float t = time_f * tSpeed;
    float strength = 0.6 + 1.6 * (ampControl * 0.5);

    vec2 center = vec2(0.5); // Fixed center since iMouse is gone

    vec3 colA = sampleWarp(uv, t, strength, center, iResolution);
    vec3 colB = sampleWarp(uv + vec2(0.01, -0.007),
                           t + 3.14,
                           strength * 0.9,
                           center,
                           iResolution);

    float blend = 0.5 + 0.5 * sin(t * 0.25);
    vec3 finalCol = mix(colA, colB, blend);

    color = vec4(finalCol, 1.0);
}