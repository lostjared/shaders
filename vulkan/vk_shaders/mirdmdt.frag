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

layout(set = 0, binding = 0) uniform sampler2D samp;


layout(location = 0) out vec4 color;

void main() {
    vec2 uv = gl_FragCoord.xy / iResolution;
    vec2 centeredUV = uv * 2.0 - 1.0;

    float angle = time_f * 0.5;
    mat2 rotation = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));

    if (centeredUV.x < 0.0) {
        centeredUV.x = -centeredUV.x;
        centeredUV = rotation * centeredUV;
    } else {
        centeredUV = rotation * centeredUV;
    }

    centeredUV = mod(centeredUV, 1.0);
    vec2 mirroredUV = centeredUV * 0.5 + 0.5;
    vec4 texColor = texture(samp, mirroredUV);

    color = texColor;
}
