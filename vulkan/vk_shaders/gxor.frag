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
    vec4 texColor = texture(samp, uv);
    float xor_effect_r = mod((texColor.r * 255.0) + sin(uv.x * 20.0 + time_f) * 255.0, 256.0) / 255.0;
    float xor_effect_g = mod((texColor.g * 255.0) + cos(uv.y * 20.0 - time_f) * 255.0, 256.0) / 255.0;
    float xor_effect_b = mod((texColor.b * 255.0) + sin((uv.x + uv.y) * 20.0 + time_f) * 255.0, 256.0) / 255.0;
    vec3 finalColor = mix(texColor.rgb, vec3(xor_effect_r, xor_effect_g, xor_effect_b), 0.5);
    color = vec4(finalColor, texColor.a);
}

