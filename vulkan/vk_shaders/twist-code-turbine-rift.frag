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
    float a = atan(p.y, p.x) + time_f * 1.8 + 0.8 / r;
    float bladeCount = 18.0;
    float blade = fract(a / TAU * bladeCount + r * 7.0);
    float edge = smoothstep(0.02, 0.22, blade) * (1.0 - smoothstep(0.68, 0.98, blade));
    float bend = sin(blade * TAU + r * 65.0 - time_f * 15.0);
    float qa = a + (blade - 0.5) * 0.5 + bend * 0.08;
    float qr = r + bend * 0.045;
    vec2 uv = fract(vec2(cos(qa), sin(qa)) * qr / ar + 0.5);
    vec4 c0 = texture(samp, uv);
    vec4 c1 = texture(samp, fract(uv.yx + vec2(blade, r) * 0.15));
    vec3 rgb = mix(c0.rgb, c1.bgr, (1.0 - edge) * 0.5);
    rgb *= 0.48 + edge * 0.9;
    color = vec4(rgb, c0.a);
}
