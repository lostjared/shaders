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
    vec3 edgeColor = (edge > threshold) ? vec3(1.0) : vec3(0.0);

    return edgeColor;
}

vec3 rainbowBackground(vec2 uv, float time_f) {
    float hue = mod(time_f + length(uv), 1.0);
    float r = abs(hue * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(hue * 6.0 - 2.0);
    float b = 2.0 - abs(hue * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

void main(void) {
    vec3 edgeColor = edgeDetection(samp, tc);
    vec3 bgColor = rainbowBackground(tc, time_f);
    vec3 finalColor = mix(bgColor, vec3(1.0), step(0.5, edgeColor.r));
    color = vec4(finalColor, 1.0);
}
