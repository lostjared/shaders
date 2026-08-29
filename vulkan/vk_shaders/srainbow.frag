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



float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

vec3 rainbow(float t) {
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

void main(void) {
    vec2 uv = tc * 2.0 - 1.0;
    uv.y *= iResolution.y / iResolution.x;
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);
    float dispersion = 0.02;
    vec2 dir = normalize(uv);
    vec2 offset_r = tc + dir * dispersion;
    vec2 offset_g = tc;
    vec2 offset_b = tc - dir * dispersion;
    float r = texture(samp, offset_r).r;
    float g = texture(samp, offset_g).g;
    float b = texture(samp, offset_b).b;
    vec3 prism_color = vec3(r, g, b);
    float t = fract((angle / (2.0 * 3.14159)) + time_f * 0.1);
    vec3 rainbow_color = rainbow(t);
    float rainbow_factor = 0.5;
    vec3 final_color = mix(prism_color, rainbow_color, rainbow_factor);
    
    float time_t = pingPong(time_f, 4.0) + 2.0;
    
    color = vec4(sin(final_color * time_t), 1.0);
}

