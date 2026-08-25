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

// Powerup glow: bright radial bloom with rotating color cycle.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 p = tc - 0.5;
    vec3 c = texture(samp, tc).rgb;
    float glow = pow(max(0.0, 1.0 - length(p) * 1.8), 2.0);
    vec3 tint = 0.55 + 0.45 * cos(vec3(0.0, 2.1, 4.2) + time_f * 2.0);
    vec2 px = 1.0 / max(iResolution, vec2(1.0));
    vec3 bloom = texture(samp, tc + vec2(px.x * 3.0, 0)).rgb + texture(samp, tc - vec2(px.x * 3.0, 0)).rgb;
    bloom += texture(samp, tc + vec2(0, px.y * 3.0)).rgb + texture(samp, tc - vec2(0, px.y * 3.0)).rgb;
    c = c * 0.8 + bloom * 0.08 + tint * glow * 0.45;
    color = vec4(c, 1.0);
}
