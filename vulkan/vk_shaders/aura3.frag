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


const float PI = 3.1415926535897932384626433832795;

float pingPong(float x, float length){
    float m = mod(x, length*2.0);
    return m <= length ? m : length*2.0 - m;
}

void main(void){
    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float radius = mix(0.8, 1.2, 0.5 + 0.5 * sin(time_f * 1.3));
    radius *= 2.0;

    float r = length(uv);
    float glow = smoothstep(radius, radius - 0.25, r);

    vec4 base = texture(samp, tc);

    vec3 pink = vec3(1.0, 0.2, 0.6);
    float pulse = 0.5 + 0.5 * sin(time_f * 3.0);
    vec3 aura = pink * glow * pulse * 1.5;

    vec3 blended = mix(base.rgb, aura + base.rgb * 0.6, glow);
    color = vec4(blended, base.a);
}
