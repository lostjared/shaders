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



mat4 rotationMatrixX(float angle) {
    return mat4(
        1.0, 0.0, 0.0, 0.0,
        0.0, cos(angle), -sin(angle), 0.0,
        0.0, sin(angle), cos(angle), 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 rotationMatrixY(float angle) {
    return mat4(
        cos(angle), 0.0, sin(angle), 0.0,
        0.0, 1.0, 0.0, 0.0,
        -sin(angle), 0.0, cos(angle), 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 rotationMatrixZ(float angle) {
    return mat4(
        cos(angle), -sin(angle), 0.0, 0.0,
        sin(angle), cos(angle), 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 scaleMatrix(float scale) {
    return mat4(
        scale, 0.0, 0.0, 0.0,
        0.0, scale, 0.0, 0.0,
        0.0, 0.0, scale, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

void main(void) {
    vec2 center = vec2(0.5, 0.5);
    vec2 pos = tc - center;

    float angleX = time_f * 0.1;
    float angleY = time_f * 0.2;
    float angleZ = time_f * 0.3;

    float scale = 1.0 + 0.5 * sin(time_f * 0.5);

    mat4 rotationX = rotationMatrixX(angleX);
    mat4 rotationY = rotationMatrixY(angleY);
    mat4 rotationZ = rotationMatrixZ(angleZ);
    mat4 scaleMat = scaleMatrix(scale);

    vec4 transformedPos = scaleMat * rotationZ * rotationY * rotationX * vec4(pos, 0.0, 1.0);

    vec2 transformedTc = transformedPos.xy + center;

    color = texture(samp, transformedTc);
}
