#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

void main() {
    vec2 uv = tc;
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 d = uv - m;
    float dist = length(d);
    float pos = 1.0 + 6.0 * (1.0 - smoothstep(0.0, 0.35, dist)) + 0.25 * sin(time_f * 1.5);

    // warp coordinates based on mouse influence
    vec2 warp = d * sin(time_f * 0.8 + dist * 8.0) * 0.15 * pos;
    uv += warp;

    ivec2 coords = ivec2(uv * iResolution);
    vec4 origColor = texture(samp, uv);

    int x = coords.x;
    int y = coords.y;
    vec3 newColor = origColor.rgb;

    if ((x % 2) == 0) {
        if ((y % 2) == 0) {
            newColor.r = (1.0 - pos * origColor.r);
            newColor.b = (float(x + y) * pos) / 255.0;
        } else {
            newColor.r = (pos * origColor.r - float(y)) / 255.0;
            newColor.b = (float(x - y) * pos) / 255.0;
        }
    } else {
        if ((y % 2) == 0) {
            newColor.r = (pos * origColor.r - float(x)) / 255.0;
            newColor.b = (float(x - y) * pos) / 255.0;
        } else {
            newColor.r = (pos * origColor.r - float(y)) / 255.0;
            newColor.b = (float(x + y) * pos) / 255.0;
        }
    }

    float temp = newColor.r;
    newColor.r = newColor.b;
    newColor.b = temp;
    vec3 finalColor = (sin(time_f) > 0.0) ? vec3(1.0) - newColor : newColor;

    color = sin(vec4(finalColor, 1.0) * pingPong(time_f, 10));
    color.a = 1.0;
}
