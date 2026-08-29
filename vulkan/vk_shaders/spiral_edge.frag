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

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

void main(void) {
    float t = time_f;
    vec2 p = tc * 2.0 - 1.0;
    float k = 10.0;
    float a = 0.35 + 0.25 * sin(t * 1.7);
    p += a * vec2(sin((p.y + t) * k), cos((p.x - t) * k));
    float r = length(p);
    float ang = atan(p.y, p.x) + a * 4.0 * r * r + t * 1.2;
    vec2 s = vec2(cos(ang), sin(ang)) * r;
    vec2 uv = s * 0.5 + 0.5;
    uv.x = pingPong(uv.x + t * 1.8, 1.0);
    uv.y = pingPong(uv.y + t * 1.8, 1.0);
    color = texture(samp, uv);
}
