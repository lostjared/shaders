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
    float r = length(p) + 0.0005;
    float a = atan(p.y, p.x);

    float lane = sin(a * 14.0 + log(r) * 18.0 - time_f * 7.0);
    float counterLane = cos(a * 9.0 - log(r) * 24.0 + time_f * 5.0);
    float twist = 8.0 * (1.0 - smoothstep(0.0, 0.9, r)) + 0.9 / r;
    float qa = a + twist + time_f * 0.8 + lane * 0.14;
    float qr = r + lane * 0.045 + counterLane * 0.025;

    vec2 uv = vec2(fract(qa / TAU * 2.0 + qr * 1.5),
                   fract(-log(r) * 0.42 + a / TAU * 3.0 + time_f * 0.35));
    vec2 flow = normalize(vec2(cos(qa), sin(qa))) / ar;
    vec4 c0 = texture(samp, uv);
    vec4 c1 = texture(samp, fract(uv + flow * (0.018 * lane)));
    vec3 rgb = mix(c0.rgb, c1.bgr, 0.28 + 0.18 * counterLane);
    rgb *= 0.82 + 0.28 * abs(lane);
    color = vec4(rgb, c0.a);
}
