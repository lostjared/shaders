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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;


void main(void) {
    float frequency = 10.0;
    float amplitude = 0.02;
    float speed = 2.0;
    float rowHeight = 1.0 / 4.0;

    vec2 snake;
    if (tc.y < rowHeight) {
        snake = tc + vec2(amplitude * sin(tc.y * frequency + time_f * speed), amplitude * sin(tc.x * frequency + time_f * speed));
    } else if (tc.y < 2.0 * rowHeight) {
        snake = tc + vec2(amplitude * sin((tc.y - rowHeight) * frequency + time_f * speed), amplitude * sin(tc.x * frequency + time_f * speed));
    } else if (tc.y < 3.0 * rowHeight) {
        snake = tc + vec2(amplitude * sin((tc.y - 2.0 * rowHeight) * frequency + time_f * speed), amplitude * sin(tc.x * frequency + time_f * speed));
    } else {
        snake = tc + vec2(amplitude * sin((tc.y - 3.0 * rowHeight) * frequency + time_f * speed), amplitude * sin(tc.x * frequency + time_f * speed));
    }
    
    vec4 texColor = texture(samp, snake);
    color = texColor;
}
