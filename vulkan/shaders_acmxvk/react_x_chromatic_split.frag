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
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iamp ext.u1.z
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;









void main(void) {
    float aLow  = clamp(amp_low,  0.0, 1.0);
    float aMid  = clamp(amp_mid,  0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk   = clamp(amp_peak, 0.0, 1.0);

    float chromaStr = 0.01 + aPk * 0.04;
    float rSpeed = 5.0 + aLow * 8.0;
    float gSpeed = 7.0 + aMid * 6.0;
    float bSpeed = 3.0 + aHigh * 10.0;

    vec2 redOffset   = vec2(sin(time_f * rSpeed), cos(time_f * rSpeed)) * chromaStr;
    vec2 greenOffset = vec2(cos(time_f * gSpeed), sin(time_f * gSpeed)) * chromaStr;
    vec2 blueOffset  = vec2(sin(time_f * bSpeed), cos(time_f * bSpeed)) * chromaStr;

    float r = texture(samp, tc + redOffset).r;
    float g = texture(samp, tc + greenOffset).g;
    float b = texture(samp, tc + blueOffset).b;

    vec3 col = vec3(r, g, b);
    col *= 1.0 + aPk * 0.5;
    color = vec4(col, 1.0);
}
