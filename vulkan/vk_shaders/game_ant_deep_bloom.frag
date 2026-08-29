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

// Deep bloom — soft glow on bright pixels (5-tap sample).
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 ts = 1.5 / iResolution;
    vec3 c  = texture(samp, tc).rgb;
    vec3 b  = texture(samp, tc + vec2( ts.x, 0.0)).rgb
            + texture(samp, tc + vec2(-ts.x, 0.0)).rgb
            + texture(samp, tc + vec2(0.0,  ts.y)).rgb
            + texture(samp, tc + vec2(0.0, -ts.y)).rgb;
    b *= 0.25;
    vec3 hi = max(b - 0.40, 0.0);
    vec3 outc = c + hi * 1.30;
    color = vec4(outc, 1.0);
}
