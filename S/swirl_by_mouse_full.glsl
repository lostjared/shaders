#version 330 core

out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float alpha;
uniform vec4 iMouse;

float pingPong(float x,float len){float m=mod(x,len*2.0);return m<=len?m:len*2.0-m;}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453123);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);vec2 u=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1.0,0.0)),u.x),mix(hash(i+vec2(0.0,1.0)),hash(i+vec2(1.0,1.0)),u.x),u.y);}

void main(){
    vec2 uv=(tc*iResolution-0.5*iResolution)/iResolution.y;
    float t=time_f*0.7;
    float beat=abs(sin(time_f*3.14159))*0.2+0.8;
    float radius=length(uv);
    float angle=atan(uv.y,uv.x)+t*0.5;
    float radMod=pingPong(radius+t*0.3,0.5);
    float wave=sin(radius*10.0-t*6.0)*0.5+0.5;
    float distortion=sin((radius+t*0.5)*8.0)*beat*0.1;
    vec2 m=(iMouse.z>0.5?iMouse.xy:0.5*iResolution)/iResolution;
    vec2 d=tc-m;
    float dist=length(d);
    float r=mix(0.12,0.35,beat);
    float s=smoothstep(r,0.0,dist);
    float k=6.0*(0.6+0.4*beat);
    float ang=atan(d.y,d.x)+s*(r-dist)*k;
    vec2 swirlUV=m+vec2(cos(ang),sin(ang))*dist;
    vec3 base=texture(samp,swirlUV+distortion).rgb;
    float n=noise(uv*10.0+t*0.5)*0.2;
    vec3 modv=vec3(sin(angle*3.0+radMod*8.0+wave*6.2831+n),
                   sin(angle*4.0-radMod*6.0+wave*4.1230+n),
                   sin(angle*5.0+radMod*10.0-wave*3.4560-n))*0.5+0.5;
    vec3 lightDir=normalize(vec3(0.5,0.5,1.0));
    vec3 norm=normalize(vec3(uv,sqrt(max(0.0,1.0-dot(uv,uv)))));
    float light=dot(norm,lightDir)*0.5+0.5;
    vec3 col=base*modv*light*1.2*beat;
    color=vec4(col,alpha);
}
