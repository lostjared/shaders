#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 movingGradient(vec2 uv, vec2 c, float t, float aspect) {
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (uv - c) * ar;
    vec2 d = normalize(vec2(cos(t * 0.27), sin(t * 0.31)));
    float s = dot(p, d);
    float band = 0.5 + 0.5 * sin(s * 6.28318530718 * 0.35 + t * 0.9);
    float h = fract(s * 0.22 + t * 0.07 + 0.15 * sin(t * 0.33));
    float S = 0.75 + 0.25 * sin(t * 0.21 + s * 2.0);
    float V = 0.75 + 0.25 * band;
    vec3 base = hsv2rgb(vec3(h, S, V));
    float edge = smoothstep(0.2, 0.8, band);
    return mix(base * 0.6, base, edge);
}

mat2 rot2(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 p = (tc - m) * ar;

    float T = 8.0;
    float s = pingPong(time_f, T) / T;
    float e = s * s * (3.0 - 2.0 * s);
    float z = min(1.0, mix(0.55, 2.8, e));
    float spin = 0.35 * (e - 0.5);
    p = rot2(spin) * p;
    vec2 uvTex = p / z / ar + m;

    vec4 baseTex = texture(samp, uvTex);
    vec3 grad = movingGradient(tc, m, time_f, aspect);

    float vign = 1.0 - smoothstep(0.78, 1.15, length((tc - m) * ar));
    vign = mix(0.86, 1.18, vign);

    float chroma = 0.0025 * (0.2 + abs(e - 0.5) * 1.8);
    vec3 texRGB;
    texRGB.r = texture(samp, uvTex + vec2(chroma, 0.0)).r;
    texRGB.g = texture(samp, uvTex).g;
    texRGB.b = texture(samp, uvTex - vec2(chroma, 0.0)).b;

    float growMask = smoothstep(0.0, 0.6, e) * smoothstep(1.0, 0.6, e);
    float pulse = 0.5 + 0.5 * sin(time_f * 2.0 + length(p) * 24.0);
    float mixTex = 0.55 + 0.35 * growMask;
    float mixGrad = 0.35 + 0.25 * (1.0 - growMask);

    vec3 screenBlend = 1.0 - (1.0 - texRGB) * (1.0 - grad);
    vec3 col = mix(texRGB, screenBlend, mixGrad);
    col = mix(col, baseTex.rgb, mixTex);
    col *= vign * (0.85 + 0.15 * pulse);

    vec3 bloom = col * col * 0.18 + pow(max(col - 0.6, 0.0), vec3(2.0)) * 0.12;
    col += bloom;

    col = sin(col * (0.5 + 0.5 * pingPong(time_f, 12.0)));
    col = clamp(col, vec3(0.08), vec3(0.96));

    color = vec4(col, 1.0);
}
