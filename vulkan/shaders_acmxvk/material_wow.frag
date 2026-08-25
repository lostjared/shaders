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
uniform sampler2D mat_samp;



void main(void) {
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    float timeBasedBlockSize = 2.0 + 62.0 * abs(sin(time_f));
    int blockSize = int(timeBasedBlockSize);

    ivec2 blockOrigin = ivec2(uv * iResolution) / blockSize * blockSize;

    vec3 currentPixel = texture(samp, blockOrigin / iResolution).rgb;
    vec3 previousPixel = texture(mat_samp, blockOrigin / iResolution).rgb;

    vec3 mixedPixel = mix(currentPixel, previousPixel, 0.5);
    color = vec4(mixedPixel, 1.0);
}
