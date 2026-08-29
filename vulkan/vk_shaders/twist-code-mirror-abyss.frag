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



vec2 mirrorTile(vec2 uv) {
    return 1.0 - abs(fract(uv * 0.5) * 2.0 - 1.0);
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * ar;
    float r = length(p) + 0.001;
    float a = atan(p.y, p.x);
    float lattice = sin(a * 16.0 + r * 42.0 - time_f * 8.0);
    a += 1.35 / r + time_f * 0.85 + lattice * 0.2;
    float rr = fract(-log(r) * 0.45 + time_f * 0.37) * (0.45 + r);
    vec2 q = vec2(cos(a), sin(a)) * rr / ar + 0.5;
    vec2 uv = mirrorTile(q * (3.0 + 0.7 * sin(time_f * 0.6)));
    vec4 c0 = texture(samp, uv);
    vec4 c1 = texture(samp, mirrorTile(uv.yx * 1.7 + lattice * 0.08));
    float mirrorPulse = 0.5 + 0.5 * cos(a * 8.0 - time_f * 6.0);
    color = vec4(mix(c0.rgb, c1.bgr, 0.2 + mirrorPulse * 0.45), c0.a);
}
