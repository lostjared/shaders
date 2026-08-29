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
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y
#define value_alpha_b ext.custom_uniforms[1].w
#define value_alpha_g ext.custom_uniforms[1].z
#define value_alpha_r ext.custom_uniforms[1].y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;





vec3 overlayBlend(vec3 base, vec3 blend, float opacity) {
    vec3 c2 = blend * 2.0;
    vec3 c1 = 1.0 - 2.0 * (1.0 - blend);
    vec3 result = mix(base * c2, c1, step(0.5, base));
    return mix(base, result, opacity);
}

void main(void) {
    vec2 ar = vec2(iResolution.x / iResolution.y, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 uv = tc;

    vec2 p = (uv - m) * ar;
    float dist = length(p);
    float angle = atan(p.y, p.x) + time_f * 5.0;
    float spiral = cos(10.0 * dist - angle);

    float ring = smoothstep(0.1, 0.2, abs(spiral) - dist * 0.5);
    float falloff = 1.0 - smoothstep(0.0, 0.6, dist);
    float mask = clamp(ring * falloff, 0.0, 1.0);

    vec3 neon = vec3(value_alpha_r, value_alpha_g, value_alpha_b);
    vec3 base = texture(samp, uv).rgb;
    vec3 blended = overlayBlend(base, neon, mask);

    color = vec4(blended, 1.0);
}
