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



uniform vec4 inc_valuex;

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void)
{
    color = texture(samp, tc);
    vec2 pos = gl_FragCoord.xy / iResolution;
    vec4 s = color * sin(inc_valuex / 255.0 * time_f);
    color[0] += s[0] * pos[0];
    color[1] += s[1] * pos[1];
 
    float time_t = pingPong(time_f, 20) + 2.0;
    
    color = sin(color * time_t);
    color.a = 1.0;
}
