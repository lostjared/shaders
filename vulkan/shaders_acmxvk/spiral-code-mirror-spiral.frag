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
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;


const float TAU = 6.28318530718;

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p);
    float angle = atan(p.y, p.x) + log(radius + 0.035) * 3.6 - time_f * 0.32;
    float slice = TAU / 8.0;
    angle = abs(mod(angle + slice * 0.5, slice) - slice * 0.5);

    vec2 q = vec2(cos(angle), sin(angle)) * radius;
    q = abs(q);
    if (q.y > q.x) {
        q = q.yx;
    }
    vec2 uv = mirrorUV(0.5 + q / vec2(aspect, 1.0));
    vec3 source = texture(samp, uv).rgb;
    float seam = pow(1.0 - clamp(angle / (slice * 0.5), 0.0, 1.0), 12.0);
    float spiralLine = pow(0.5 + 0.5 * sin(radius * 35.0 - angle * 8.0), 14.0);
    vec3 result = source * vec3(0.93, 0.98, 1.04);
    result += vec3(0.19, 0.25, 0.31) * seam * 0.28 + vec3(0.10, 0.15, 0.21) * spiralLine;
    color = vec4(result, texture(samp, tc).a);
}
