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
layout(set = 0, binding = 0) uniform sampler2D samp;




void main(void){
    vec2 normCoord = gl_FragCoord.xy / iResolution.xy;
    float aspect = iResolution.x / iResolution.y;
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    vec2 p = normCoord - m;
    p.x *= aspect;

    float eps = 1e-6;
    float r = length(p) + eps;
    float theta = atan(p.y, p.x);

    float base = 1.7;
    float period = log(base);
    float t = time_f * 0.5;

    float k = fract((log(r) - t) / period);
    float rw = exp(k * period);

    float twistAmount = 15.0;
    theta += (1.0 - clamp(rw, 0.0, 1.0)) * twistAmount * sin(time_f) + t * 1.57079632679;

    vec2 q = vec2(cos(theta), sin(theta)) * rw;
    q.x /= aspect;

    vec2 uv = fract(q + m);
    color = texture(samp, uv);
}
