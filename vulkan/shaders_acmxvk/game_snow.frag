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

// Snow falling - soft white flakes, light density.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float h21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float total = 0.0;
    for (int layer = 0; layer < 3; ++layer) {
        float scale = 30.0 + float(layer) * 25.0;
        float speed = 0.15 + float(layer) * 0.10;
        vec2 uv = tc * vec2(iResolution.x / iResolution.y, 1.0) * scale;
        uv.x += sin(uv.y * 0.5 + time_f) * 0.3;
        uv.y += time_f * speed * 10.0;
        vec2 cell = floor(uv);
        vec2 f = fract(uv) - 0.5;
        float r = h21(cell);
        float flake = smoothstep(0.18, 0.0, length(f)) * step(0.96, r);
        total += flake * (1.0 - 0.2 * float(layer));
    }
    c += vec3(total) * 0.55;
    color = vec4(clamp(c, 0.0, 1.0), 1.0);
}
