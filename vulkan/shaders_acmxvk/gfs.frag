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

    float zoom = 1.0 + 0.5 * sin(time_f);
    centeredUV *= zoom;

    float angle = time_f * 1.5 * zoom;
    float cosA = cos(angle);
    float sinA = sin(angle);
    centeredUV = vec2(
        cosA * centeredUV.x - sinA * centeredUV.y,
        sinA * centeredUV.x + cosA * centeredUV.y
    );

    float prismAngle = atan(centeredUV.y, centeredUV.x);
    float radius = length(centeredUV);

    float prismEffect = sin(prismAngle * 3.0) * 0.1;
    vec2 refractedUV = vec2(
        centeredUV.x + prismEffect * cos(prismAngle),
        centeredUV.y + prismEffect * sin(prismAngle)
    );

    refractedUV = refractedUV * 0.5 + 0.5;

    vec4 texColorPrism = texture(samp, refractedUV);
    vec4 texColorOriginal = texture(samp, uv);

    float blendFactor = smoothstep(0.5, 0.7, radius);
    color = mix(texColorOriginal, texColorPrism, 1.0 - blendFactor);
}
