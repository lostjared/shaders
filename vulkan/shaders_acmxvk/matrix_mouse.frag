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
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;




float hash21(vec2 p){p=fract(p*vec2(123.34,456.21));p+=dot(p,p+34.45);return fract(p.x*p.y);}
mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,-s,s,c);}

void main(){
    vec2 ar = vec2(iResolution.x/iResolution.y,1.0);
    vec2 m = (iMouse.z>0.5)? (iMouse.xy/iResolution) : vec2(0.5);
    vec2 p = (tc - m)*ar;
    float r = length(p);
    float base = mix(0.015,0.08,smoothstep(0.0,0.9,r));
    float wob = 0.012*sin(time_f*0.9+5.0*r);
    float ts = base + wob;
    vec2 gid = floor(p/ts);
    vec2 cellCenter = (gid+0.5)*ts;
    float ang = 0.6*sin(time_f*0.7 + hash21(gid)*6.2831);
    vec2 local = rot(ang)*(p-cellCenter);
    vec2 jitter = (hash21(gid+13.7)-0.5)*0.25*ts*vec2(cos(time_f+gid.x),sin(time_f*1.3+gid.y));
    vec2 uv = (cellCenter + jitter)/ar + m;
    vec4 tex = texture(samp, uv + local*0.35);
    vec2 edge = abs(fract(p/ts)-0.5);
    float border = smoothstep(0.01,0.0,min(edge.x,edge.y));
    vec3 tint = mix(tex.rgb, vec3(0.0,1.0,0.2), 0.25+0.25*sin(time_f+hash21(gid)*3.7));
    vec3 col = mix(vec3(0.08,0.12,0.08), tint, border);
    float vig = 1.0 - 0.65*smoothstep(0.7,1.1,length((tc-0.5)*vec2(ar.x,1.0)));
    color = vec4(col*vig,1.0);
    color =  mix(color, texture(samp, tc), 0.5);
}
