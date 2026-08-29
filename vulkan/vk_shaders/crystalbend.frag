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
#define iResolution ext.u0.zw
#define time_f ext.u2.y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;




float PI = 3.141592653589793;

float mirror1(float x, float m){
    float p = mod(x, m*2.0);
    return p > m ? (2.0*m - p) : p;
}

vec2 kaleido(vec2 p, float seg){
    vec2 c = vec2(0.5);
    vec2 d = p - c;
    float a = atan(d.y, d.x);
    float r = length(d);
    float m = PI / max(2.0, seg);
    a = mirror1(a, m);
    return c + vec2(cos(a), sin(a)) * max(r, 1e-6);
}

void main(){
    vec2 uv = tc;
    float drive = clamp(amp + uamp, 0.0, 2.0);
    float seg = floor(mix(5.0, 12.0, clamp(drive*0.5, 0.0, 1.0)));
    vec2 k = kaleido(uv, seg);

    float r = length(k - 0.5);
    vec2 dir = normalize(k - 0.5 + vec2(1e-6, 0.0));

    float bend = (0.06 + 0.14 * uamp) / (r + 0.04);
    vec2 wob = 0.012 * (0.3 + amp) * vec2(sin(32.0*r - 1.7*time_f), cos(28.0*r - 1.3*time_f));
    vec2 base = k + dir * bend + wob;

    float disp = (0.001 + 0.004 * amp) / (r + 0.04);
    vec2 tR = base + dir * disp;
    vec2 tG = base;
    vec2 tB = base - dir * disp;

    vec3 warped;
    warped.r = texture(samp, tR).r;
    warped.g = texture(samp, tG).g;
    warped.b = texture(samp, tB).b;

    float wedge = PI / max(2.0, seg);
    float a = atan((k - 0.5).y, (k - 0.5).x);
    float edge = abs(mod(a + wedge, 2.0*wedge) - wedge) / wedge;
    float edgeGlow = pow(1.0 - edge, 6.0) * mix(0.10, 0.35, clamp(amp, 0.0, 1.0));
    warped += edgeGlow;

    vec3 orig = texture(samp, uv).rgb;

    float clarityBias = 0.45;
    float effectAmt = clamp(clarityBias + 0.4 * clamp(drive*0.5, 0.0, 1.0), 0.0, 1.0);
    float spatial = smoothstep(0.0, 0.85, r);
    float mixAmt = clamp(mix(effectAmt*0.7, effectAmt, spatial), 0.0, 1.0);

    vec3 outc = mix(orig, warped, mixAmt);
    color = vec4(outc, 1.0);
}
