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


vec4 colorShift(vec4 col) {
    return vec4(
        0.5 + 0.5 * cos(col.r * 3.14159265 * 0.5),
        0.5 + 0.5 * cos(col.g * 3.14159265 * 0.5),
        0.5 + 0.5 * cos(col.b * 3.14159265 * 0.5),
        col.a
    );
}

void main(void) {
    float time_t = pingPong(time_f, 10.0) + 1.0;
    vec4 pix = texture(samp, tc);
    pix = pix * time_t;
    pix = colorShift(pix);
    pix.rgb = mix(vec3(1.0),pix.rgb,0.8);
    color = pix;
}
