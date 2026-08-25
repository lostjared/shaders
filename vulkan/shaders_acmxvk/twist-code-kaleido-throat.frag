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



const float TAU = 6.28318530718;

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * ar;
    float r = length(p) + 0.001;
    float a = atan(p.y, p.x) + time_f * 0.65 + 1.15 / r;
    float wedge = TAU / 12.0;
    a = abs(mod(a + wedge * 0.5, wedge) - wedge * 0.5);
    a += sin(r * 60.0 - time_f * 11.0) * 0.24;
    float depth = fract(-log(r) * 0.68 + time_f * 0.72);
    float rr = fract(r * 3.2 + depth + sin(a * 24.0) * 0.08);
    vec2 q = vec2(cos(a), sin(a)) * rr;
    vec2 uv = fract(q / ar + 0.5);
    vec2 uv2 = fract(vec2(a / wedge, depth + r * 2.0));
    vec4 c0 = texture(samp, uv);
    vec4 c1 = texture(samp, uv2);
    float facets = pow(abs(cos(a * 12.0)), 5.0);
    color = vec4(mix(c0.rgb, c1.bgr, 0.36) * (0.72 + facets * 0.58), c0.a);
}
