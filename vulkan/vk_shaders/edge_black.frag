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

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;


vec3 edgeDetection(sampler2D tex, vec2 uv) {
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
    float threshold = 0.3;
    vec3 color = (edge > threshold) ? vec3(1.0) : vec3(0.0);

    return color;
}

void main(void) {
    vec3 edgeColor = edgeDetection(samp, tc);
    color = vec4(edgeColor, 1.0);
}






