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
#define random_seed ext.custom_uniforms[6].z
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;




vec3 rainbow(float t) {
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

float noise(vec2 p) {
    return texture(samp, p).r;
}

vec2 swirl(vec2 p, float t, float seed) {
    float radius = length(p);
    float angle = atan(p.y, p.x) + sin(t + radius * 10.0 + noise(p * 10.0 + seed) * 10.0) * 0.5;
    return vec2(cos(angle), sin(angle)) * radius;
}

void main(void) {
    float mod_time = mod(time_f, 25.0);
    vec2 uv = tc * 2.0 - 1.0;
    uv.y *= iResolution.y / iResolution.x;

    uv = swirl(uv, mod_time * 0.1, random_seed);
    uv *= 0.5;

    float n = noise(uv * 0.5 + mod_time * 0.05);
    vec3 rainbow_color = rainbow(n + mod_time * 0.1);

    vec4 original_color = texture(samp, tc);
    vec3 blended_color = mix(original_color.rgb, rainbow_color, 0.5);

    color = vec4(blended_color, original_color.a);
}
