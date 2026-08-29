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



float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec3 pencilSketch(sampler2D tex, vec2 uv) {
    float edgeThreshold = 0.3;
    vec2 offset = vec2(1.0 / iResolution.x, 1.0 / iResolution.y);

    float gx =
          -1.0 * texture(tex, uv + vec2(-offset.x, -offset.y)).r
        + -2.0 * texture(tex, uv + vec2(-offset.x, 0.0)).r
        + -1.0 * texture(tex, uv + vec2(-offset.x, offset.y)).r
        +  1.0 * texture(tex, uv + vec2(offset.x, -offset.y)).r
        +  2.0 * texture(tex, uv + vec2(offset.x, 0.0)).r
        +  1.0 * texture(tex, uv + vec2(offset.x, offset.y)).r;

    float gy =
          -1.0 * texture(tex, uv + vec2(-offset.x, -offset.y)).r
        + -2.0 * texture(tex, uv + vec2(0.0, -offset.y)).r
        + -1.0 * texture(tex, uv + vec2(offset.x, -offset.y)).r
        +  1.0 * texture(tex, uv + vec2(-offset.x, offset.y)).r
        +  2.0 * texture(tex, uv + vec2(0.0, offset.y)).r
        +  1.0 * texture(tex, uv + vec2(offset.x, offset.y)).r;

    float edge = sqrt(gx * gx + gy * gy);
    float noise = random(uv * time_f) * 0.1;
    float sketch = (edge > edgeThreshold) ? 0.0 : 1.0;
    sketch += noise;

    vec3 color = vec3(sketch);

    return color;
}

void main(void) {
    vec3 sketchColor = pencilSketch(samp, tc);
    color = vec4(sketchColor, 1.0);
}
