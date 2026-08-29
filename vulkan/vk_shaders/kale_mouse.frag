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




mat3 rotX(float a){float s=sin(a),c=cos(a);return mat3(1,0,0,0,c,-s,0,s,c);}
mat3 rotY(float a){float s=sin(a),c=cos(a);return mat3(c,0,s,0,1,0,-s,0,c);}
mat3 rotZ(float a){float s=sin(a),c=cos(a);return mat3(c,-s,0,s,c,0,0,0,1);}

void main(void) {
    float asp=iResolution.x/iResolution.y;
    vec2 ar=vec2(asp,1.0);
    vec2 m=(iMouse.z>0.5)?(iMouse.xy/iResolution):vec2(0.5);

    vec2 p=(tc-m)*ar;
    vec3 v=vec3(p,1.0);
    float ax=0.28*sin(time_f*0.7);
    float ay=0.24*cos(time_f*0.6);
    float az=time_f*0.7;
    vec3 r=(rotZ(az)*rotY(ay)*rotX(ax))*v;
    float zf=1.0/(1.0+0.7*r.z);
    vec2 q=r.xy*zf;

    float N=6.0;
    float stepA=6.28318530718/N;
    float ang=atan(q.y,q.x);
    float rad=length(q);
    ang=mod(ang,stepA);
    ang=abs(ang-stepA*0.5);
    vec2 k=vec2(cos(ang),sin(ang))*rad;

    vec2 uv=k/ar+m;
    uv=clamp(uv,0.0,1.0);

    color=texture(samp,uv);
}
