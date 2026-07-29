#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float PI(){return 3.14159265358979323846;}

vec3 triadMask(vec2 uv){
    float px=floor(uv.x*iResolution.x);
    float m=mod(px,3.0);
    vec3 a=vec3(1.10,0.88,0.88);
    vec3 b=vec3(0.88,1.10,0.88);
    vec3 c=vec3(0.88,0.88,1.10);
    return mix(mix(c,b,step(1.0,m)),a,step(2.0,m));
}

float scanline(vec2 uv){
    float y=uv.y*iResolution.y;
    return 0.84+0.16*sin(PI()*y);
}

vec3 halation(vec2 uv){
    vec2 px=1.0/iResolution;
    vec3 s=vec3(0.0);
    s+=texture(samp,uv+vec2( px.x, 0.0)).rgb*0.10;
    s+=texture(samp,uv+vec2(-px.x, 0.0)).rgb*0.10;
    s+=texture(samp,uv+vec2( 0.0, px.y)).rgb*0.10;
    s+=texture(samp,uv+vec2( 0.0,-px.y)).rgb*0.10;
    s+=texture(samp,uv+vec2( px.x, px.y)).rgb*0.06;
    s+=texture(samp,uv+vec2(-px.x, px.y)).rgb*0.06;
    s+=texture(samp,uv+vec2( px.x,-px.y)).rgb*0.06;
    s+=texture(samp,uv+vec2(-px.x,-px.y)).rgb*0.06;
    return s;
}

void main(){
    vec2 uv=tc;

    float jitter=(sin(time_f*120.0)+sin((uv.y+time_f*0.61)*87.0))*0.0005;
    uv.x+=jitter;

    vec2 center=vec2(0.5);
    vec2 dir=uv-center;
    float aberr=0.0016+0.0010*sin(time_f*0.8);
    float r=texture(samp, uv+dir*aberr).r;
    float g=texture(samp, uv).g;
    float b=texture(samp, uv-dir*aberr).b;
    vec3 base=vec3(r,g,b);

    vec3 bloom=halation(uv)*0.35;
    vec3 linear=pow(base,vec3(2.2))+pow(bloom,vec3(2.2));

    float sl=scanline(uv);
    vec3 tri=triadMask(uv);
    float grille=0.94+0.06*sin(uv.x*iResolution.x*PI()*0.5);
    float flick=0.992+0.008*sin(time_f*360.0);

    vec3 shaped=linear*tri*sl*grille*flick;

    vec3 outc=pow(shaped,vec3(1.0/2.2));
    color=vec4(outc,1.0);
}
