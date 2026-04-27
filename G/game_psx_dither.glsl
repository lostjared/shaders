#version 330 core
// PSX-style dithered low-bit color.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float bayer[16] = float[](
        0.0, 8.0, 2.0,10.0,
       12.0, 4.0,14.0, 6.0,
        3.0,11.0, 1.0, 9.0,
       15.0, 7.0,13.0, 5.0);
    int idx = int(mod(gl_FragCoord.x, 4.0)) + int(mod(gl_FragCoord.y, 4.0)) * 4;
    float t = (bayer[idx] / 16.0 - 0.5) / 16.0;
    c += t;
    c = floor(c * 16.0) / 15.0;
    color = vec4(clamp(c, 0.0, 1.0), 1.0);
}
