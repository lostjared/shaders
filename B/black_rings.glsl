#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;
uniform float iTime;
uniform int iFrame; 
uniform float iTimeDelta;
uniform vec4 iDate;
uniform vec2 iMouseClick;
uniform float iFrameRate;
uniform vec3 iChannelResolution[4];
uniform float iChannelTime[4];
uniform float iSampleRate;

const float PI=3.1415926535897932384626433832795;

float pingPong(float x,float l){float m=mod(x,l*2.0);return m<=l?m:l*2.0-m;}
float hash(float n){return fract(sin(n)*43758.5453123);}
float n2(vec2 p){
    vec2 i=floor(p),f=fract(p);
    float a=hash(i.x+i.y*57.0);
    float b=hash(i.x+1.0+i.y*57.0);
    float c=hash(i.x+(i.y+1.0)*57.0);
    float d=hash(i.x+1.0+(i.y+1.0)*57.0);
    vec2 u=f*f*(3.0-2.0*f);
    return mix(mix(a,b,u.x),mix(c,d,u.x),u.y);
}
float fbm(vec2 p){
    float s=0.0,a=0.5;
    for(int i=0;i<5;i++){s+=a*n2(p);p*=2.02;a*=0.5;}
    return s;
}
vec3 hsv2rgb(vec3 c){
    vec4 K=vec4(1.0,2.0/3.0,1.0/3.0,3.0);
    vec3 p=abs(fract(c.xxx+K.xyz)*6.0-K.www);
    return c.z*mix(K.xxx,clamp(p-K.xxx,0.0,1.0),c.y);
}
vec2 rot(vec2 p,float a){float s=sin(a),c=cos(a);return mat2(c,-s,s,c)*p;}

vec2 kale(vec2 uv,float seg,vec2 c,float aspect){
    vec2 p=uv-c;p.x*=aspect;
    float a=atan(p.y,p.x),r=length(p);
    float stepA=2.0*PI/seg;
    a=mod(a,stepA);
    a=abs(a-stepA*0.5);
    vec2 q=vec2(cos(a),sin(a))*r;
    q.x/=aspect;
    return q+c;
}

vec3 tentBlur3(sampler2D img,vec2 uv,vec2 res){
    vec2 ts=1.0/res;
    vec3 s00=texture(img,uv+ts*vec2(-1.0,-1.0)).rgb;
    vec3 s10=texture(img,uv+ts*vec2(0.0,-1.0)).rgb;
    vec3 s20=texture(img,uv+ts*vec2(1.0,-1.0)).rgb;
    vec3 s01=texture(img,uv+ts*vec2(-1.0,0.0)).rgb;
    vec3 s11=texture(img,uv).rgb;
    vec3 s21=texture(img,uv+ts*vec2(1.0,0.0)).rgb;
    vec3 s02=texture(img,uv+ts*vec2(-1.0,1.0)).rgb;
    vec3 s12=texture(img,uv+ts*vec2(0.0,1.0)).rgb;
    vec3 s22=texture(img,uv+ts*vec2(1.0,1.0)).rgb;
    return (s00+2.0*s10+s20+2.0*s01+4.0*s11+2.0*s21+s02+2.0*s12+s22)/16.0;
}

void main(){
    vec2 R=iResolution;
    float aspect=R.x/max(R.y,1.0);
    vec2 uv=tc;
    vec2 cuv=(uv-0.5)*vec2(aspect,1.0);
    float t=time_f+iTime+float(iFrame)*max(iTimeDelta,0.0);
    float fr=max(iFrameRate,1.0);
    float sr=clamp(iSampleRate/48000.0,0.25,4.0);
    float dateSeed=dot(iDate,vec4(1.0,31.0,12.0,0.001));
    float chs=0.0;
    for(int i=0;i<4;i++){
        chs+=0.5+0.5*sin(iChannelTime[i]*0.73+float(i)*1.17);
        chs+=0.0003*length(iChannelResolution[i].xy)+0.000001*iChannelResolution[i].z;
    }
    float aMix=clamp(amp*0.7+uamp*0.3,0.0,20.0);
    vec2 m=(iMouse.w>0.5?iMouse.xy/iResolution:vec2(0.5));
    vec2 click=mix(vec2(0.5),iMouseClick,step(0.0,length(iMouseClick)));
    float clickBurst=exp(-10.0*length(uv-click))*step(0.0,length(iMouseClick));
    float seg=3.0+mod(float(iFrame),9.0)+smoothstep(0.0,1.0,fract(t*0.11+chs*0.07))*3.0;
    float swirl=0.6+0.4*sin(t*0.3+chs*0.5);
    vec2 warp0=vec2(fbm(uv*6.0+vec2(t*0.3,chs)),fbm(uv*6.0+vec2(-t*0.4,chs*0.7)))-(0.5);
    vec2 warp1=vec2(n2(uv*12.0+rot(vec2(t*0.7,chs),t*0.2)),n2(uv*12.0-rot(vec2(t*0.6,chs),t*0.25)))-(0.5);
    vec2 warp=(warp0*0.035+warp1*0.02)*(1.0+0.6*sin(t*0.8))*sr*(0.75+0.25*sin(fr*0.02));
    vec2 kUV=kale(uv,seg,m,aspect);
    vec2 p=(kUV-m)*vec2(aspect,1.0);
    p=rot(p,swirl*(0.5+0.5*sin(t*0.21+chs)));
    float r=length(p);
    float rip=sin(22.0*r - t*9.0 - chs*3.0 + aMix*0.15)*0.015/(1.0+20.0*r);
    vec2 dir=normalize(p+1e-5);
    vec2 uA=uv+warp+dir*rip;
    vec2 uB=mix(uv,fract((p*0.18+warp*2.0)/vec2(aspect,1.0)+m),0.85);
    vec2 uC=uv+rot(warp,0.5+t*0.1);
    float zoom=0.9+0.25*sin(pingPong(t*0.6+chs,2.0)*PI+clickBurst*2.0);
    uA=(uA-m)*zoom+m;
    uB=(uB-m)*(1.0/zoom)+m;
    uC=(uC-m)*(1.0+0.15*sin(t*0.9+fr*0.03))+m;
    vec4 t1=texture(samp,fract(uA));
    vec4 t2=texture(samp,fract(uB));
    vec4 t3=texture(samp,fract(uC));
    vec3 blur=tentBlur3(samp,fract(uv+warp*2.0),iResolution);
    float hueBase=fract(t*0.07+dateSeed*0.13+chs*0.11+float(iFrame)*0.0007);
    float sat=0.65+0.35*sin(chs+t*0.6+sr);
    float val=0.55+0.45*sin(t*0.7+dot(uv,vec2(3.1,2.7)));
    vec3 tint=hsv2rgb(vec3(hueBase+length(p)*0.3+0.07*sin(iTimeDelta*120.0+fr*0.02),sat,val));
    vec4 mixA=mix(t1,t2,0.5+0.5*sin(t+chs+aMix*0.05));
    vec4 mixB=mix(t2,t3,0.5+0.5*cos(t*1.3+sr));
    vec4 mixC=mix(mixA,mixB,0.5+0.5*sin(t*0.7+dateSeed));
    float ring=smoothstep(0.0,0.8,sin(log(r+1e-3)*9.5+t*1.2+fr*0.01));
    float pulse=0.5+0.5*sin(t*2.0+r*28.0+chs*2.0+aMix*0.1)+clickBurst;
    float vign=1.0-smoothstep(0.75,1.15,length((uv-m)*vec2(aspect,1.0)));
    vec3 col=mixC.rgb;
    col=col*(0.75+0.25*ring)*(0.85+0.15*pulse)*vign;
    col=mix(col,blur,0.12*(0.5+0.5*sin(t+chs)));
    col*=tint*(0.9+0.1*sin(float(iFrame)*0.02+chs));
    vec3 bloom=col*col*0.18+pow(max(col-0.6,0.0),vec3(2.0))*0.12;
    col+=bloom;
    vec3 base=texture(samp,tc).rgb;
    float mixTex=pingPong(pulse*PI,5.0)*0.22+0.1*abs(sin(aMix*0.05));
    col=mix(col,base,mixTex);
    col=clamp(col,vec3(0.02),vec3(0.98));
    color=vec4(col,1.0);
}
