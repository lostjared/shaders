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


void main(void) {
    vec2 normCoord = gl_FragCoord.xy / iResolution.xy;
float diagonalDistance = (normCoord.x + normCoord.y - 1.0) * sqrt(2.0);
    float antiDiagonalDistance = (normCoord.x - normCoord.y) * sqrt(2.0);
    float diagonalWave = sin((diagonalDistance + time_f) * 5.0); // Wave frequency and speed
    float antiDiagonalWave = cos((antiDiagonalDistance + time_f) * 5.0);
    float combinedWave = (diagonalWave + antiDiagonalWave) * 0.5;

    vec2 waveAdjusted = vec2(tc.x + combinedWave * 0.202, tc.y + combinedWave * 0.202);
    
    color = texture(samp, waveAdjusted);
}
