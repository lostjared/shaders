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



float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 uv = tc;
    float squareSize = 0.2;
    vec2 gridCoord = floor(uv / squareSize);
    vec2 localCoord = fract(uv / squareSize);

    float diag = mod(gridCoord.x + gridCoord.y, 2.0);
    vec4 texColor = texture(samp, uv);

    if (diag == 0.0) {
        float shift = sin(time_f + gridCoord.x * 0.5) * 0.1;
        localCoord.x += shift; 
        uv = fract(gridCoord * squareSize + localCoord);
        texColor = texture(samp, uv);
    }

    color = texColor;
}

