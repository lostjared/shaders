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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;



vec2 prismWarp(vec2 uv, float phase) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (uv - 0.5) * ar;
    float r = length(p) + 0.001;
    float a = atan(p.y, p.x);
    float shard = sin(a * 21.0 + r * 63.0 - time_f * 12.0 + phase);
    a += 1.18 / r + time_f * 0.9 + shard * 0.23 + phase;
    r += shard * 0.038 + phase * 0.006;
    return fract(vec2(cos(a), sin(a)) * r / ar + 0.5);
}

void main(void) {
    vec2 ur = prismWarp(tc, 0.18);
    vec2 ug = prismWarp(tc, 0.0);
    vec2 ub = prismWarp(tc, -0.18);
    vec3 rgb = vec3(texture(samp, ur).r,
                    texture(samp, ug).g,
                    texture(samp, ub).b);
    vec3 crossed = texture(samp, fract(ug.yx * 1.25)).bgr;
    float flare = pow(abs(sin(length(tc - 0.5) * 90.0 - time_f * 15.0)), 7.0);
    rgb = mix(rgb, crossed, flare * 0.3) + flare * vec3(0.18, 0.06, 0.25);
    color = vec4(rgb, texture(samp, ug).a);
}
