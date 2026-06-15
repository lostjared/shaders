#version 330 core

in vec2 tc;
out vec4 color;

// Live feed and cache layers
uniform sampler2D samp;
uniform sampler2D samp1;
uniform sampler2D samp2;
uniform sampler2D samp3;
uniform sampler2D samp4;
uniform sampler2D samp5;
uniform sampler2D samp6;
uniform sampler2D samp7;
uniform sampler2D samp8;
uniform float time_f;
uniform vec2 iResolution;

vec4 sampleCache(int idx, vec2 uv) {
    if (idx == 0)
        return texture(samp1, uv);
    if (idx == 1)
        return texture(samp2, uv);
    if (idx == 2)
        return texture(samp3, uv);
    if (idx == 3)
        return texture(samp4, uv);
    if (idx == 4)
        return texture(samp5, uv);
    if (idx == 5)
        return texture(samp6, uv);
    if (idx == 6)
        return texture(samp7, uv);
    return texture(samp8, uv);
}

void main() {
    color = texture(samp, tc);
    vec2 tc_off = vec2(0.01, 0.01);
    for (int i = 0; i <= 6; ++i) {
        color = mix(color, sampleCache(i, tc + tc_off), 0.5);
        tc_off += vec2(0.02, 0.01);
    }
    color = clamp(color, vec4(0.0), vec4(1.0));
}
