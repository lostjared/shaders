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
#define seed ext.custom_uniforms[2].z
#define time_f ext.u2.y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;







float h1(float n){return fract(sin(n*91.345+37.12)*43758.5453123);}
vec2 h2(vec2 p){return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);}

vec2 rot(vec2 v,float a){float c=cos(a),s=sin(a);return vec2(c*v.x-s*v.y,s*v.x+c*v.y);}

void main(void){
    vec2 uv=tc;

    float a=clamp(amp,0.0,1.0);
    float ua=clamp(uamp,0.0,1.0);

    vec2 m = iMouse.z>0.5 ? (iMouse.xy/iResolution) : fract(vec2(0.37+0.11*sin(time_f*0.63),0.42+0.13*cos(time_f*0.57)));

    float baseStr = mix(0.002,0.018,a);
    float freq = mix(6.0,22.0,ua);
    float t = time_f;

    float s1 = sin((uv.y+0.07*sin(uv.x*3.0)) * freq + t*1.3);
    float s2 = cos((uv.x+uv.y*0.5) * (freq*0.7) + t*1.7);
    vec2 wv = vec2(s1,s2)*baseStr;

    vec2 d = uv - m;
    float r = length(d)+1e-5;
    float fall = smoothstep(0.5,0.0,r);
    float swirl = (0.15+0.45*ua+0.25*a) * fall * (0.7+0.3*sin(t*2.1+seed));
    vec2 tang = rot(normalize(d), 1.5707963);
    vec2 air = tang * swirl * (0.02+0.18*a) * (0.6+0.4*cos(uv.y*40.0+t*3.0));

    vec2 nJit = (h2(uv*vec2(233.3,341.9)+t+seed)-0.5);
    vec2 jitter = nJit * (0.0005 + 0.004*ua) * (0.5+0.5*sin(t*5.0+seed*3.0));

    vec2 uv0 = uv + wv + air + jitter;

    float ca = 0.0015 + 0.004*a;
    vec4 c;
    c.r = texture(samp, uv0 + vec2( ca,0.0)).r;
    c.g = texture(samp, uv0                          ).g;
    c.b = texture(samp, uv0 + vec2(-ca,0.0)).b;

    float pulse = 0.005*(0.5+0.5*sin(t*3.7+seed));
    c.rgb += vec3(pulse)*ua;

    color = vec4(c.rgb,1.0);
}
