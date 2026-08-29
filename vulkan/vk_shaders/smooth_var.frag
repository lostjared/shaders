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
#define amp ext.u1.y
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;





void main(void) {
    vec2 texel = 1.0 / iResolution;
    float spread = 1.5;
    vec2 o = texel * spread;

    vec4 c0  = texture(samp, tc);
    vec4 cN  = texture(samp, tc + vec2(0.0,  o.y));
    vec4 cS  = texture(samp, tc + vec2(0.0, -o.y));
    vec4 cE  = texture(samp, tc + vec2( o.x, 0.0));
    vec4 cW  = texture(samp, tc + vec2(-o.x, 0.0));
    vec4 cNE = texture(samp, tc + vec2( o.x,  o.y));
    vec4 cNW = texture(samp, tc + vec2(-o.x,  o.y));
    vec4 cSE = texture(samp, tc + vec2( o.x, -o.y));
    vec4 cSW = texture(samp, tc + vec2(-o.x, -o.y));

    vec4 mean = (c0 + cN + cS + cE + cW + cNE + cNW + cSE + cSW) / 9.0;

    
    float variance =
        dot(abs(c0 - mean).rgb, vec3(0.333)) +
        dot(abs(cN - mean).rgb, vec3(0.333)) +
        dot(abs(cS - mean).rgb, vec3(0.333)) +
        dot(abs(cE - mean).rgb, vec3(0.333)) +
        dot(abs(cW - mean).rgb, vec3(0.333)) +
        dot(abs(cNE - mean).rgb, vec3(0.333)) +
        dot(abs(cNW - mean).rgb, vec3(0.333)) +
        dot(abs(cSE - mean).rgb, vec3(0.333)) +
        dot(abs(cSW - mean).rgb, vec3(0.333));

    variance /= 9.0;

    
    float strength = smoothstep(0.05, 0.15, variance) * clamp(amp + uamp, 0.0, 1.0);

    vec4 tent = (c0 * 4.0 +
                 (cN + cS + cE + cW) * 2.0 +
                 (cNE + cNW + cSE + cSW)) / 16.0;

    color = mix(c0, tent, strength);
}
