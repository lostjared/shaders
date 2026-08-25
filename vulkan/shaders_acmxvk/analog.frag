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



vec3 analogEffect(vec2 uv) {
    vec3 col = texture(samp, uv).rgb;

    float offset = 0.002;
    col.r = texture(samp, uv + vec2(offset, 0.0)).r;
    col.b = texture(samp, uv - vec2(offset, 0.0)).b;

    float noise = fract(sin(dot(uv.xy + time_f, vec2(12.9898, 78.233))) * 43758.5453);
    col += noise * 0.05;

    float scanline = sin(uv.y * iResolution.y * 3.0 + time_f * 20.0) * 0.05;
    col -= vec3(scanline);

    float vignette = smoothstep(1.0, 0.8, length(uv - 0.5) * 1.5);
    col *= vignette;

    return col;
}

void main(void) {
    vec2 uv = tc;
    vec3 col = analogEffect(uv);
    color = vec4(col, 1.0);
}
