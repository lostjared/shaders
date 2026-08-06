#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

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
    pix.rgb = mix(vec3(1.0), sin(pix.rgb * time_t), 0.8);
    color = pix;
}
