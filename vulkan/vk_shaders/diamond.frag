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


vec3 hash3(vec2 p) {
    vec3 q = vec3(dot(p, vec2(127.1, 311.7)),
                  dot(p, vec2(269.5, 183.3)),
                  dot(p, vec2(419.2, 371.9)));
    return fract(sin(q) * 43758.5453);
}

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
    vec2 uv = tc * iResolution / vec2(iResolution.y);
    vec2 skewedUv = uv;
    skewedUv.x = (uv.x + uv.y) * 0.5;
    skewedUv.y = (uv.x - uv.y) * 0.5;
    float scale = abs(sin(time_f)) * 20.0 + 1.0;
    skewedUv *= scale;
    vec2 c = floor(skewedUv);
    vec2 checker = mod(c, 2.0);
    bool isEvenDiamond = (checker.x == checker.y);
    vec3 diamondColor = hash3(c);
    vec3 finalColor = isEvenDiamond ? diamondColor * 0.8 : diamondColor * 0.5;
    color = xor_RGB(vec4(finalColor, 1.0), texture(samp, tc));
    
}
