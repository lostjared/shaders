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
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

vec3 rainbow(float t) {
    float r = sin(6.28318 * t + 0.0);
    float g = sin(6.28318 * t + 2.09439);
    float b = sin(6.28318 * t + 4.18878);
    return vec3(r, g, b) * 0.5 + 0.5;
}

void main(void) {
    float scale = 5.0;
    float speed = 0.2;
    float gradient_pos = 0.5 + 0.5 * sin((tc.x * scale + tc.y * scale) + time_f * speed);
    vec3 color_gradient = rainbow(gradient_pos);

    float time_t = pingPong(time_f, 10.0) + 2.0;
    vec4 ctx = texture(samp, tc);
    color = vec4(sin(ctx.rgb * time_t), ctx.a);
    color = mix(color, vec4(color_gradient, 1.0), 0.5);
}
