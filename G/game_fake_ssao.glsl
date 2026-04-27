#version 330 core
// Subtle screen-space ambient occlusion fake using local darkening of edges.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 px = 1.0 / iResolution;
    vec3 c = texture(samp, tc).rgb;
    float lumC = dot(c, vec3(0.299, 0.587, 0.114));
    float occ = 0.0;
    for (int i = 0; i < 8; ++i) {
        float a = float(i) * 0.7853981;
        vec2 o = vec2(cos(a), sin(a)) * px * 2.0;
        float lumS = dot(texture(samp, tc + o).rgb, vec3(0.299, 0.587, 0.114));
        occ += max(0.0, lumC - lumS);
    }
    occ = clamp(occ * 0.9, 0.0, 0.45);
    color = vec4(c * (1.0 - occ), 1.0);
}
