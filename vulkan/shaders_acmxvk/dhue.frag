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



float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}


vec4 adjustHue(vec4 color, float angle) {
    float U = cos(angle);
    float W = sin(angle);
    mat3 rotationMatrix = mat3(
        0.299, 0.587, 0.114,
        0.299, 0.587, 0.114,
        0.299, 0.587, 0.114
    ) + mat3(
        0.701, -0.587, -0.114,
        -0.299, 0.413, -0.114,
        -0.3, -0.588, 0.886
    ) * U + mat3(
        0.168, 0.330, -0.497,
        -0.328, 0.035, 0.292,
        1.25, -1.05, -0.203
    ) * W;
    return vec4(rotationMatrix * color.rgb, color.a);
}

void main() {
    vec2 uv = (tc - 0.5) * iResolution / min(iResolution.x, 
iResolution.y);
    float dist = length(uv);
    float ripple = sin(dist * 12.0 - pingPong(time_f, 10.0) * 10.0) * exp(-dist * 4.0);
    vec4 sampledColor = texture(samp, tc + ripple * 0.01);
    float hueShift = pingPong(time_f, 10.0) * ripple * 2.0;
    color = adjustHue(sampledColor, hueShift);
}

