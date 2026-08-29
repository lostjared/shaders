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

layout(location = 0) in vec2 tc; 
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;

void main(void)
{

		 vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    uv = uv - floor(uv);     
    vec2 normCoord = ((tc.xy / iResolution.xy) * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);

    float distanceFromCenter = length(normCoord);
    float wave = sin(distanceFromCenter * 12.0 - time_f * 4.0);

    vec2 tcAdjusted = uv + (normCoord * 0.301 * wave);

    vec4 textureColor = texture(samp, tcAdjusted);
    color = textureColor;
}
