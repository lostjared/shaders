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

void main(void) {

    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    uv = uv - floor(uv);  

    float timeVar = time_f * 0.5;
    vec2 noise = vec2(
        pingPong(uv.x + timeVar, 1.0),
        pingPong(uv.y + timeVar, 1.0)
    );

    float stretchFactorX = 1.0 + 0.3 * sin(time_f + uv.y * 10.0);
    float stretchFactorY = 1.0 + 0.3 * cos(time_f + uv.x * 10.0);
    
    vec2 distortedUV = vec2(
        uv.x * stretchFactorX + noise.x * 0.1,
        uv.y * stretchFactorY + noise.y * 0.1
    );

    color = texture(samp, distortedUV);
}
