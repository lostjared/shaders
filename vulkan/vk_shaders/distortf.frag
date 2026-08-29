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


void main() {
    vec2 uv = tc;
    vec2 center = vec2(0.5, 0.5);
    vec2 offset = uv - center;

    float fractalFactor = sin(length(offset) * 10.0 + time_f * 2.0) * 0.1;
    vec2 fractalUV = uv + fractalFactor * normalize(offset);
    float grid = abs(sin(fractalUV.x * 50.0) * sin(fractalUV.y * 50.0));
    grid = step(0.7, grid);
    float angle = atan(offset.y, offset.x) + fractalFactor * sin(time_f);
    float radius = length(offset);
    vec2 swirlUV = center + radius * vec2(cos(angle), sin(angle));

    vec2 combinedUV = mix(swirlUV, fractalUV, 0.5);
    vec4 texColor = texture(samp, combinedUV);
    vec3 rainbow = vec3(0.5 + 0.5 * sin(time_f + texColor.r),
                        0.5 + 0.5 * sin(time_f + texColor.g + 2.0),
                        0.5 + 0.5 * sin(time_f + texColor.b + 4.0));

    vec3 finalColor = mix(texColor.rgb * rainbow, vec3(grid), 0.3);

    color = vec4(finalColor, texColor.a);
}

