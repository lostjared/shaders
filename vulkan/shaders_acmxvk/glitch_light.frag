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


uniform vec4 random_var;

vec4 blendColors(float t) {
    vec4 color1 = vec4(0.6, 0.2, 0.8, 1.0);
    vec4 color2 = vec4(0.2, 0.8, 0.6, 1.0);
    vec4 color3 = vec4(0.8, 0.6, 0.2, 1.0);
    vec4 color4 = vec4(0.3, 0.4, 0.6, 1.0);
    float phase = mod(t / 20.0, 2.0 * 3.14159);
    float blend = (sin(phase) + 1.0) / 2.0;
    if (t < 25.0)
        return mix(color1, color2, blend);
    else if (t < 50.0)
        return mix(color2, color3, blend);
    else
        return mix(color3, color4, blend);
}

void main(void) {
    color = texture(samp, tc);
    float time_t = mod(time_f, 75.0);
    vec4 light = blendColors(time_t);
    color = tan(0.25 + sin((color * light) * time_t));
    color.a = 1.0;
}
