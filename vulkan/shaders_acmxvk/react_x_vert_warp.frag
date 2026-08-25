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
    float aPk   = clamp(amp_peak, 0.0, 1.0);
    float aRms  = clamp(amp_rms,  0.0, 1.0);

    float amplitude = aLow * 3.0 + 0.2;
    float distFromCenter = abs(tc.y - 0.5);
    vec2 distorted_tc = tc;
    float warpFreq = 1.0 + aMid * 4.0;
    distorted_tc.y += amplitude * (0.5 - distFromCenter) * distFromCenter * sin(time_f * warpFreq);
    distorted_tc.x += aPk * 0.05 * sin(tc.y * 30.0 + time_f * 8.0);
    distorted_tc = clamp(distorted_tc, vec2(0.0), vec2(1.0));
    color = texture(samp, distorted_tc);
}
