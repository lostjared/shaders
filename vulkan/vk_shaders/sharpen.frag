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
#define time_f ext.u2.y
#define time_speed ext.custom_uniforms[3].y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp; 




void main(void) {
    vec2 step = 1.0 / vec2(textureSize(samp, 0));
    vec4 center = texture(samp, tc);
    vec4 up     = texture(samp, tc + vec2(0.0, step.y));
    vec4 down   = texture(samp, tc + vec2(0.0, -step.y));
    vec4 left   = texture(samp, tc + vec2(-step.x, 0.0));
    vec4 right  = texture(samp, tc + vec2(step.x, 0.0));
    vec3 sharpened = (center.rgb * 5.0) - (up.rgb + down.rgb + left.rgb + right.rgb);
    color = vec4(sharpened, center.a);    
}