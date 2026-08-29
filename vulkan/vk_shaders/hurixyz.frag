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



mat3 rotationMatrixX(float angle) {
    return mat3(
        1.0, 0.0, 0.0,
        0.0, cos(angle), -sin(angle),
        0.0, sin(angle), cos(angle)
    );
}

mat3 rotationMatrixY(float angle) {
    return mat3(
        cos(angle), 0.0, sin(angle),
        0.0,       1.0, 0.0,
       -sin(angle), 0.0, cos(angle)
    );
}

mat2 rotationMatrixZ(float angle) {
    return mat2(
        cos(angle), -sin(angle),
        sin(angle),  cos(angle)
    );
}

vec2 vortexDistortion(vec2 uv, float time) {
    vec2 center = vec2(0.5, 0.5);
    vec2 offset = uv - center;
    float distance = length(offset);
    float angle = atan(offset.y, offset.x) + sin(time + distance * 10.0) * 0.5;
    return center + vec2(cos(angle), sin(angle)) * distance;
}

void main(void) {
    vec2 uv = tc;
    float phase = mod(time_f, 3.0);

    if (phase < 1.0) {
        float angle = time_f * 2.0;
        mat3 rotation = rotationMatrixX(angle);
        uv = (rotation * vec3(uv - 0.5, 1.0)).xy + 0.5;
    } else if (phase < 2.0) {
        float angle = time_f * 2.0;
        mat3 rotation = rotationMatrixY(angle);
        uv = (rotation * vec3(uv - 0.5, 1.0)).xy + 0.5;
    } else {
        float angle = time_f * 2.0;
        mat2 rotation = rotationMatrixZ(angle);
        uv = (rotation * (uv - 0.5)) + 0.5;
    }

    uv.x = mod(uv.x + sin(time_f) * 0.2, 1.0);
    uv.y = mod(uv.y + cos(time_f) * 0.2, 1.0);

    uv = vortexDistortion(uv, time_f);
    vec4 texColor = texture(samp, uv);
    color = texColor;
}

