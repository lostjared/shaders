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
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;




float pingPong(float x, float length){
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

void main(void){
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    vec2 p = (tc - m) * ar;

    float base = 1.65;
    float period = log(base);
    float tz = time_f * 0.45;
    float r0 = length(p) + 1e-6;
    float a0 = atan(p.y, p.x) + tz * 0.35;
    float k = fract((log(r0) - tz) / period);
    float rw = exp(k * period);
    vec2 pz = vec2(cos(a0), sin(a0)) * rw;

    float time_t = pingPong(time_f, 10.0);
    float len_iso = length(pz / ar);
    float bubble = smoothstep(0.8, 1.0, 1.0 - len_iso);
    bubble = sin(bubble * time_t);

    vec2 distort = pz * (1.0 + 0.1 * sin(time_f + length(pz) * 20.0));
    distort = sin(distort * time_t);

    vec2 uv = fract(distort / ar + m);
    vec4 texColor = texture(samp, uv);
    color = mix(texColor, vec4(1.0), bubble);
}
