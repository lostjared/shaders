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
    float a = atan(p.y, p.x);
    float front = fract(time_f * 0.42);
    float shock = exp(-abs(fract(r * 1.35 - front + 0.5) - 0.5) * 26.0);
    float spiral = sin(r * 58.0 - a * 13.0 - time_f * 14.0);
    a += 1.35 / r + shock * 1.4 + time_f * 0.72;
    r += spiral * (0.025 + shock * 0.065);
    vec2 uv = fract(vec2(cos(a), sin(a)) * r / ar + 0.5);
    vec2 radial = vec2(cos(a), sin(a)) / ar;
    vec4 c0 = texture(samp, uv);
    vec4 c1 = texture(samp, fract(uv + radial * shock * 0.055));
    vec3 rgb = mix(c0.rgb, c1.bgr, shock * 0.58);
    rgb += vec3(0.12, 0.35, 0.8) * shock * 0.5;
    color = vec4(rgb, c0.a);
}
