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



void main() {
		 vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    uv = uv - floor(uv);     
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);
    
    float spiral = angle + radius * 5.0 - time_f;
    float reflection = mod(spiral, 3.14159 * 2.0);
    
    vec2 spiralUV = vec2(cos(spiral), sin(spiral)) * radius + 0.5;
    vec2 reflectUV = vec2(cos(reflection), sin(reflection)) * radius + 0.5;

    vec4 gradientColor = vec4(0.5 + 0.5 * cos(time_f + radius * 10.0), 0.5 + 0.5 * sin(time_f + radius * 10.0), 0.5 + 0.5 * cos(time_f - radius * 10.0), 1.0);
    vec4 textureColor = texture(samp, reflectUV);
    
    color = mix(gradientColor, textureColor, 0.5);
}
