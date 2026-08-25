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
    vec2 uv = tc * 2.0 - 1.0;
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);
    
    float spinningSpeed = mix(5.0, 1.0, radius);
    float spinningAngle = angle + time_f * spinningSpeed;
    
    vec2 spinningUV = vec2(cos(spinningAngle), sin(spinningAngle)) * radius * 0.5 + 0.5;
    vec4 texColor = texture(samp, spinningUV);
    
    float centerGlow = exp(-radius * 10.0);
    float outerGlow = smoothstep(0.4, 0.5, radius) * 0.5 + 0.5;
    float glow = max(centerGlow, outerGlow);
    
    color = texColor * vec4(glow, glow, glow, 1.0);
    color = xor_RGB(color, texture(samp, tc));
}
