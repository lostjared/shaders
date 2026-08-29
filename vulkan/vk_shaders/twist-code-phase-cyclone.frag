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
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * ar;
    float r = length(p) + 0.001;
    float a = atan(p.y, p.x);
    float phaseA = sin(r * 47.0 - a * 8.0 - time_f * 10.0);
    float phaseB = cos(r * 53.0 + a * 11.0 + time_f * 7.0);
    float interference = phaseA * phaseB;
    a += time_f + 1.2 / r + interference * 0.55;
    r += (phaseA + phaseB) * 0.035;
    vec2 uvA = fract(vec2(cos(a), sin(a)) * r / ar + 0.5);
    vec2 uvB = fract(vec2(cos(-a + phaseB), sin(-a + phaseB)) * (r + 0.04) / ar + 0.5);
    vec4 c0 = texture(samp, uvA);
    vec4 c1 = texture(samp, uvB);
    float gate = smoothstep(-0.25, 0.25, interference);
    vec3 rgb = mix(c0.rgb, c1.bgr, gate * 0.62);
    rgb *= 0.8 + abs(interference) * 0.55;
    color = vec4(rgb, c0.a);
}
