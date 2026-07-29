#version 330 core
// Pencil sketch overlay - lightly multiplied edges, image still visible.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 px = 1.0 / iResolution;
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float gx = dot(texture(samp, tc + vec2(px.x, 0)).rgb - texture(samp, tc - vec2(px.x, 0)).rgb, vec3(0.333));
    float gy = dot(texture(samp, tc + vec2(0, px.y)).rgb - texture(samp, tc - vec2(0, px.y)).rgb, vec3(0.333));
    float edge = clamp(sqrt(gx*gx + gy*gy) * 4.0, 0.0, 1.0);
    vec3 outc = c * (1.0 - edge * 0.55);
    color = vec4(outc, 1.0);
}
