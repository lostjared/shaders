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




mat3 rotX(float a){float s=sin(a),c=cos(a);return mat3(1,0,0, 0,c,-s, 0,s,c);}
mat3 rotY(float a){float s=sin(a),c=cos(a);return mat3(c,0,s, 0,1,0, -s,0,c);}
mat3 rotZ(float a){float s=sin(a),c=cos(a);return mat3(c,-s,0, s,c,0, 0,0,1);}

void main(void){
    float aspect=iResolution.x/iResolution.y;
    vec2 ar=vec2(aspect,1.0);
    vec2 m=(iMouse.z>0.5)?(iMouse.xy/iResolution):vec2(0.5);

    vec2 p2=(tc-m)*ar;
    float ax=0.25*sin(time_f*0.7);
    float ay=0.25*cos(time_f*0.6);
    float az=time_f*0.5;

    vec3 p3=vec3(p2,1.0);
    mat3 R=rotZ(az)*rotY(ay)*rotX(ax);
    vec3 r=R*p3;

    float k=0.6;
    float zf=1.0/(1.0+r.z*k);
    vec2 q=r.xy*zf;

    float dist=length(p2);
    float scale=1.0+0.2*sin(dist*15.0-time_f*2.0);
    q*=scale;

    float eps=1e-6;
    float base=1.7;
    float period=log(base);
    float t=time_f*0.45;
    float rad=length(q)+eps;
    float ang=atan(q.y,q.x)+t*0.35*6.2831853;
    float kf=fract((log(rad)-t)/period);
    float rw=exp(kf*period);
    vec2 qwrap=vec2(cos(ang),sin(ang))*rw;

    vec2 uv=qwrap/ar+m;
    uv=fract(uv);
    color=texture(samp,uv);
}
