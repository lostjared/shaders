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
    vec2 center = vec2(0.5) + vec2(sin(time_f * 0.73), cos(time_f * 0.91)) * 0.11;
    vec2 p = (tc - center) * ar;
    p += vec2(sin(p.y * 9.0 + time_f * 2.7), cos(p.x * 8.0 - time_f * 2.2)) * 0.055;
    float r = length(p) + 0.001;
    float a = atan(p.y, p.x);
    float coil = sin(-log(r) * 15.0 + a * 6.0 - time_f * 9.0);
    a += 1.05 / r + coil * 0.3 + time_f * 0.8;
    vec2 uv = vec2(fract(a / TAU * 3.0 - log(r) * 0.7),
                   fract(-log(r) * 0.9 + coil * 0.1 + time_f * 0.55));
    vec4 c0 = texture(samp, uv);
    vec4 c1 = texture(samp, fract(uv + vec2(coil, -coil) * 0.055));
    float scales = pow(abs(coil), 2.0);
    color = vec4(mix(c0.rgb, c1.gbr, 0.25 + scales * 0.35) * (0.7 + scales * 0.5), c0.a);
}
