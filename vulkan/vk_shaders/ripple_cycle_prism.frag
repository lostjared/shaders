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

layout(set = 0, binding = 0) uniform sampler2D samp;


void main(void) {
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec2 reflectedUV = vec2(1.0 - uv.x, uv.y);
    float noise = sin(reflectedUV.y * 50.0 + time_f * 5.0) * 0.01;
    float distortionX = noise;
    float distortionY = cos(reflectedUV.x * 50.0 + time_f * 5.0) * 0.01;
    vec2 distortion = vec2(distortionX, distortionY);
    float r = texture(samp, reflectedUV + distortion * 1.2).r;
    float g = texture(samp, reflectedUV + distortion * 0.8).g;
    float b = texture(samp, reflectedUV + distortion * 0.4).b;
    color = vec4(r, g, b, 1.0);
}
