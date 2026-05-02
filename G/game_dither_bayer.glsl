#version 330 core
// 4x4 Bayer-ordered dither down to a 4-level retro palette.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float bayer4(vec2 p) {
    int x = int(mod(p.x, 4.0));
    int y = int(mod(p.y, 4.0));
    int i = x + y * 4;
    float m[16] = float[16](
        0.0, 8.0, 2.0, 10.0,
        12.0, 4.0, 14.0, 6.0,
        3.0, 11.0, 1.0, 9.0,
        15.0, 7.0, 13.0, 5.0);
    return m[i] / 16.0;
}

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float t = bayer4(gl_FragCoord.xy) - 0.5;
    c += t * (1.0 / 4.0);
    c = floor(c * 4.0) / 3.0;
    color = vec4(clamp(c, 0.0, 1.0), 1.0);
}
