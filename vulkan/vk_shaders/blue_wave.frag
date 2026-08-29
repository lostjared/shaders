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
#define amp ext.u1.y
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;





float sat(float x){return clamp(x,0.0,1.0);}

void main(void){
    vec2 uv = tc;
    vec2 m = (iMouse.z>0.0||iMouse.w>0.0)? iMouse.xy/iResolution : vec2(0.5);
    float v = 0.4 + amp*0.2;
    float s = 0.22;
    float width = 0.10;
    float base = mod(time_f*v, s);
    vec2 dir = normalize(uv - m + 1e-6);
    float r = distance(uv, m);

    float waveSum = 0.0;
    for(int k=0;k<4;k++){
        float rc = base + float(k)*s;
        float a = (r - rc)/width;
        waveSum += exp(-a*a);
    }

    vec2 duv = dir * waveSum * (0.015 + 0.015*uamp);
    vec4 tex = texture(samp, uv + duv);

    float blend = sat(waveSum * (0.45 + 0.55*uamp));
    vec3 blue = mix(tex.rgb, vec3(0.06, 0.28, 1.0), blend);
    color = vec4(blue, 1.0);
}
