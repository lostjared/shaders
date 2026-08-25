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
#define amp ext.u1.y
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;





float PI = 3.141592653589793;

float mirror1(float x, float m) {
    float p = mod(x, m * 2.0);
    return p > m ? (2.0 * m - p) : p;
}

vec2 kaleido(vec2 p, vec2 c, float seg) {
    vec2 d = p - c;
    float a = atan(d.y, d.x);
    float r = length(d);
    float m = PI / max(2.0, seg);
    a = mirror1(a, m);
    return c + vec2(cos(a), sin(a)) * max(r, 1e-6);
}

void main(void) {
    vec2 uv = tc;
    vec2 mouse = iMouse.xy / iResolution.xy;
    mouse = clamp(mouse, 0.0, 1.0);

    float seg = floor(4.0 + (amp + uamp) * 8.0);
    vec2 k = kaleido(uv, mouse, seg);

    float r = length(k - mouse);
    vec2 dir = normalize(k - mouse + vec2(1e-6, 0.0));

    float bendBase = 0.15 + 0.35 * uamp;
    float bend = bendBase / (r + 0.02);
    vec2 wob = 0.02 * (0.5 + amp) * vec2(sin(40.0 * r - 2.0 * time_f), cos(40.0 * r - 1.5 * time_f));
    vec2 base = k + dir * bend + wob;

    float disp = (0.002 + 0.01 * amp) / (r + 0.02);
    vec2 tR = base + dir * disp;
    vec2 tG = base;
    vec2 tB = base - dir * disp;

    vec3 c;
    c.r = texture(samp, tR).r;
    c.g = texture(samp, tG).g;
    c.b = texture(samp, tB).b;

    vec2 dk = k - mouse;
    float a = atan(dk.y, dk.x);
    float wedge = PI / max(2.0, seg);
    float edge = abs(mod(a + wedge, 2.0 * wedge) - wedge) / wedge;
    float edgeGlow = pow(1.0 - edge, 6.0) * (0.4 + 0.6 * amp);
    c += edgeGlow;

    float influence = smoothstep(0.35, 0.0, length(uv - mouse));
    vec3 orig = texture(samp, uv).rgb;
    vec3 outc = mix(orig, c, influence);

    color = vec4(outc, 1.0);
}
