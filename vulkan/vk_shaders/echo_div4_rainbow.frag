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
#define restore_black ext.custom_uniforms[2].y
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;




vec3 rainbow(float t) {
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    vec2 uv = tc * 2.0 - 1.0;
    uv.y *= iResolution.y / iResolution.x;

    float t = pingPong(time_f, 15.0);

    float wave = sin(uv.x * 10.0 + t * 2.0) * 0.1;
    float expand = 0.5 + 0.5 * sin(t * 2.0);
    vec2 spiral_uv = uv * expand + vec2(cos(t), sin(t)) * 0.2;

    float angle = atan(spiral_uv.y + wave, spiral_uv.x) + t * 2.0;

    vec3 rainbow_color = rainbow(angle / (2.0 * 3.14159));
    vec4 original_color = texture(samp, tc);
    vec3 blended_color = mix(original_color.rgb, rainbow_color, 0.5);

    vec4 color_result = vec4(sin(blended_color * t), original_color.a);

    vec4 color2 = texture(samp, tc / 2);
    vec2 tc1 = tc;
    vec2 tc2 = tc;
    tc1[0] = 1.0 - tc1[0];
    tc2[1] = 1.0 - tc2[1];
    vec4 color3 = texture(samp, tc1 / 4);
    vec4 color4 = texture(samp, tc2 / 4);
    color_result = (color_result * 0.4) + (color2 * 0.4) + (color3 * 0.4) + (color4 * 0.4);

    color = color_result;
}
