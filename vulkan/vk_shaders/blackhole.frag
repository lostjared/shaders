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

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 uv = tc * 2.0 - 1.0;
    uv *= iResolution.x / iResolution.y;
    float dist = length(uv);
    float timeEffect = mod(time_f * 0.1, 3.0);
    float pullIntensity = pow(dist, 1.0 + 4.0 * timeEffect);
    vec2 pulledUV = uv * pullIntensity;
    pulledUV = (pulledUV / (iResolution.x / iResolution.y)) * 0.5 + 0.5;
    vec4 texColor = texture(samp, sin(pulledUV * timeEffect));
    color = vec4(texColor.rgb, 1.0);
}
