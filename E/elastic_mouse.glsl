#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec4 iMouse;

float random(vec2 st){return fract(sin(dot(st,vec2(12.9898,78.233)))*43758.5453);}
float noise(vec2 p){
    vec2 ip=floor(p),fp=fract(p);
    float a=random(ip);
    float b=random(ip+vec2(1.0,0.0));
    float c=random(ip+vec2(0.0,1.0));
    float d=random(ip+vec2(1.0,1.0));
    fp=fp*fp*(3.0-2.0*fp);
    return mix(a,b,fp.x)+(c-a)*fp.y*(1.0-fp.x)+(d-b)*fp.x*fp.y;
}
float fractalNoise(vec2 p){
    float v=0.0;
    v+=noise(p*1.0)*1.0;
    v+=noise(p*2.0)*0.5;
    v+=noise(p*4.0)*0.25;
    v+=noise(p*8.0)*0.125;
    return v/1.875;
}

void main(){
    vec2 center=vec2(0.5);
    vec2 uv=tc;
    vec2 m=(iMouse.z>0.0)?iMouse.xy:center;
    float mouseInfluence=1.0-smoothstep(0.0,0.5,length(m-uv));
    float t=time_f*2.0;
    vec2 d=uv-center;
    float dist=length(d);
    float ang=atan(d.y,d.x);
    float twirl=10.0*(1.0-smoothstep(0.0,0.8,dist))+t*5.0;
    ang+=twirl*(0.5+sin(t*0.7)*0.5+mouseInfluence*2.0);
    vec2 disp=vec2(fractalNoise(uv*10.0+t*2.0)-0.5,fractalNoise(uv*10.0+t*1.5)-0.5)*0.2*(0.5+mouseInfluence*2.0);
    float radialWave=sin(dist*30.0-t*10.0)*0.1+sin(ang*5.0+t*5.0)*0.05;
    float radius=dist*(1.0+radialWave*2.0+mouseInfluence);
    vec2 tc2=center+vec2(cos(ang),sin(ang))*radius;
    tc2+=disp*(1.0+sin(t*10.0)*0.5);
    float rgate=random(vec2(floor(t*3.0)));
    float gInt=(sin(t*3.0)*0.5+0.5)*0.3+mouseInfluence*0.5;
    if(rgate>0.7){
        tc2.x+= (random(vec2(t))-0.5)*gInt;
        tc2.y+= (random(vec2(t*0.7))-0.5)*gInt;
    }
    tc2=clamp(tc2,0.0,1.0);
    vec2 chroma=vec2(fractalNoise(uv*50.0+t)*0.02,fractalNoise(uv*50.0+t*1.2)*0.02);
    vec4 cR=texture(samp,clamp(tc2+vec2(gInt*0.02,0.0),0.0,1.0));
    vec4 cG=texture(samp,clamp(tc2-vec2(gInt*0.02,0.0),0.0,1.0));
    vec3 col=vec3(cR.r,cG.g,cR.b);
    float scan=sin(uv.y*800.0+t*10.0)*0.1;
    col+=scan*gInt;
    col.r=texture(samp,clamp(tc2+chroma,0.0,1.0)).r;
    col.b=texture(samp,clamp(tc2-chroma,0.0,1.0)).b;
    col=mix(col,smoothstep(0.0,1.0,col*1.2),0.5);
    if(random(vec2(floor(t*0.3)))>0.97) col*=0.1;
    float vignette=1.0-smoothstep(0.4,0.8,dist);
    color=vec4(col*vignette,1.0);
}
