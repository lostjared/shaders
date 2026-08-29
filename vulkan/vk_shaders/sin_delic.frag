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
    vec2 uv = tc;
    uv.x += sin(uv.y * 10.0 + time_f) * 0.1;
    uv.y += cos(uv.x * 10.0 + time_f) * 0.1;
    float modFactor = pingPong(time_f * 0.5, 1.0);
    vec4 texColor = texture(samp, uv);
    vec3 psychedelicColor = vec3(
        texColor.r * sin(time_f + uv.y * 10.0),
        texColor.g * cos(time_f + uv.x * 10.0),
        texColor.b * sin(time_f + uv.y * 5.0)
    );
    psychedelicColor = mix(texColor.rgb, psychedelicColor, modFactor);
    float time_t =  pingPong(time_f, 10.0) + 2.0;
    color = vec4(sin(psychedelicColor * time_t), texColor.a);
}

