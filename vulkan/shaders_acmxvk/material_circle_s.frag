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
uniform sampler2D mat_samp;



vec4 xor_RGB(vec4 icolor, vec4 source) {
    ivec3 int_color;
    ivec4 isource = ivec4(source * 255);
    for(int i = 0; i < 3; ++i) {
        int_color[i] = int(255 * icolor[i]);
        int_color[i] = int_color[i]^isource[i];
        if(int_color[i] > 255)
            int_color[i] = int_color[i]%255;
        icolor[i] = float(int_color[i])/255;
    }
    icolor.a = 1.0;
return icolor;
}

void main(void) {
    vec2 center = iResolution * 0.5;
    float maxRadius = length(iResolution * 0.5);
    float radius = maxRadius * (sin(time_f * 0.5) * 0.5 + 0.5);
    vec2 normalizedCoord = gl_FragCoord.xy - center;
    normalizedCoord.x /= iResolution.x;
    normalizedCoord.y /= iResolution.y;
    float dist = length(normalizedCoord);
    if (dist < radius / maxRadius) {
        color = xor_RGB(texture(samp, tc), texture(mat_samp, tc));
    } else {
        color = texture(samp, tc);
    }
}

