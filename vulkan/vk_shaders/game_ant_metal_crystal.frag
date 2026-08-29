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

// Metal crystal — faint angular hex highlights overlay, time-shimmer.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float hex(vec2 p) {
    p = abs(p);
    return max(p.x * 0.866 + p.y * 0.5, p.y);
}

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = (tc - 0.5);
    p.x *= iResolution.x / iResolution.y;
    p *= 12.0;
    vec2 g = floor(p);
    vec2 f = fract(p) - 0.5;
    float h = hex(f);
    float shim = smoothstep(0.40, 0.50, h) * (0.5 + 0.5 * sin(time_f + g.x + g.y));
    color = vec4(c + vec3(0.5, 0.75, 1.10) * shim * 0.40, 1.0);
}
