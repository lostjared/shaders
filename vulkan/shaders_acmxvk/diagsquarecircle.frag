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

vec2 rotate(vec2 p, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

void main() {
    vec2 uv = tc;
    float squareSize = sin(0.2 * time_f);
    vec2 gridCoord = floor(uv / squareSize);
    vec2 localCoord = fract(uv / squareSize);

    float diag = mod(gridCoord.x + gridCoord.y, 2.0);
    

    if (diag == 0.0) {
        float angle = time_f + gridCoord.x * 0.5 + gridCoord.y * 0.5;
        localCoord = rotate(localCoord - 0.5, angle) + 0.5;
        uv = fract(gridCoord * squareSize + localCoord);
    }

    vec4 texColor = texture(samp, uv);
    color = texColor;
}

