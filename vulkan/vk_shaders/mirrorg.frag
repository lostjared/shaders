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

layout(set = 0, binding = 0) uniform sampler2D samp;


layout(location = 0) out vec4 color;

void main() {
    vec2 uv = gl_FragCoord.xy / iResolution;
    vec2 centeredUV = (uv - 0.5) * 2.0;

    float radius = length(centeredUV);
    float mask = smoothstep(1.0, 0.9, radius);

    float angle = atan(centeredUV.y, centeredUV.x) + time_f * 0.3;
    float refractAmount = pow(1.0 - radius, 2.0) * 0.2;

    vec2 refractedUV = vec2(
        centeredUV.x + sin(angle) * refractAmount,
        centeredUV.y + cos(angle) * refractAmount
    );

    vec2 crystalUV = refractedUV * 0.5 + 0.5;
    vec4 texColorBall = texture(samp, crystalUV);
    vec4 texColorBackground = texture(samp, uv);

    color = mix(texColorBackground, texColorBall, mask);
}
