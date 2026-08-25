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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;


float diamond(vec2 p){
    p = abs(p);
    float d = p.x + p.y;
    return 1.0 - smoothstep(0.48, 0.5, d);
}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);

    vec2 uv = tc;
    vec2 uva = uv * ar;

    float tiles = 8.0;
    vec2 gv = uva * tiles;
    vec2 f = fract(gv) - 0.5;

    float mask = diamond(f);

    vec2 mirrored = abs(fract(uv * ar) - 0.5) + 0.5;
    vec2 tuv = mirrored / ar;

    vec4 c1 = texture(samp, tuv);
    vec4 c2 = texture(samp, tuv * 0.5);
    vec4 c3 = texture(samp, tuv * 0.25);
    vec4 c4 = texture(samp, tuv * 0.125);
    vec4 mixcol = c1 * 0.4 + c2 * 0.3 + c3 * 0.2 + c4 * 0.1;

    mixcol.rgb *= mask;

    color = vec4(mixcol.rgb, 1.0);
}
