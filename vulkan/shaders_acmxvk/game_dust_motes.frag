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

// Drifting bright dust specks layered over the image. Adds atmosphere.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 uv = tc * vec2(iResolution.x / iResolution.y, 1.0) * 70.0;
    uv.y += time_f * 0.6;
    vec2 cell = floor(uv);
    vec2 f = fract(uv);
    float r = hash21(cell);
    vec2 center = vec2(hash21(cell + 17.0), hash21(cell + 43.0));
    float d = length(f - center);
    float spark = smoothstep(0.06, 0.0, d) * step(0.985, r);
    c += vec3(spark) * 0.55;
    color = vec4(c, 1.0);
}
