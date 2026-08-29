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



float pingPong(float x, float len){
    float m = mod(x, len*2.0);
    return m <= len ? m : len*2.0 - m;
}

void main(void){
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);

    vec2 p = (tc - 0.5) * ar;

    float base = 1.65;
    float period = log(base);
    float t = time_f * 0.45;
    float r = length(p) + 1e-6;
    float a = atan(p.y, p.x);

    float k = fract((log(r) - t) / period);
    float rw = exp(k * period);
    a += t * 0.4;

    vec2 z = vec2(cos(a), sin(a)) * rw;

    float swirl = sin(time_f * 0.6 + r * 5.0) * 0.1;
    z += swirl * normalize(p);

    vec2 uv = z / ar + 0.5;
    uv = fract(uv);

    vec4 tex = texture(samp, uv);
    color = tex;
}
