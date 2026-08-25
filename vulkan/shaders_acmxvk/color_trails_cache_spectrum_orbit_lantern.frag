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
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define history_head int(ext.u3.x)
#define iResolution ext.u0.zw
#define spectrum_history_head int(ext.audio_history.x)
#define spectrum_history_size int(ext.audio_history.y)
#define time_f ext.u2.y

// Floating lantern rings with gentle orbital drag and glowing cache bloom.
layout(location = 0) in vec2 tc; out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;
layout(set = 0, binding = 2) uniform sampler2DArray history;

#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif
layout(set = 0, binding = 3) uniform sampler1D spectrum0;
layout(set = 0, binding = 4) uniform sampler1DArray spectrum_history;


#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif


const float TAU=6.28318530718;
vec3 acid(float t){return 0.5+0.5*cos(TAU*(vec3(1.0,0.72,0.52)*t+vec3(0.04,0.18,0.31)));}
vec4 cacheHist(int i, vec2 uv){if(i==0)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));if(i==1)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));if(i==2)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));if(i==3)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));if(i==4)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));if(i==5)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));if(i==6)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));} 
float specHist(int i,float f){if(i==0)return texture(spectrum0,f).r;if(i==1)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(1)))).r;if(i==2)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(2)))).r;if(i==3)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(3)))).r;if(i==4)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(4)))).r;if(i==5)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(5)))).r;if(i==6)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(6)))).r;return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(7)))).r;}
vec2 orbitField(vec2 uv,float bass,float mid,float treble,float air,vec3 oldest,float layer){float r=length(uv)+0.001; float a=atan(uv.y,uv.x); float wobble=sin(r*18.0-time_f*(1.5+mid*1.5)+layer*0.5); vec2 dir=vec2(cos(a+wobble*0.6),sin(a-wobble*0.6)); dir+=vec2(oldest.r-oldest.g,oldest.b-oldest.g)*0.6; return dir*(0.009+air*0.020+mid*0.020)+uv*(0.002+bass*0.012);} 
void main(){float aspect=iResolution.x/iResolution.y; vec2 uv=(tc-0.5)*vec2(aspect,1.0); float bass=texture(spectrum0,0.04).r,mid=texture(spectrum0,0.26).r,treble=texture(spectrum0,0.50).r,air=texture(spectrum0,0.88).r; float hist=0.0; for(int i=0;i<8;i++) hist+=specHist(i,0.50); hist/=8.0; vec3 oldest=texture(history, vec3(tc+vec2(sin(time_f*0.16+uv.y*4.0),cos(time_f*0.19+uv.x*4.8))*(0.010+hist*0.022), float(CACHE_HISTORY_LAYER(7)))).rgb; vec3 live=texture(samp,tc+orbitField(uv,bass,mid,treble,air,oldest,0.0)).rgb*acid(time_f*0.05+air+length(uv)*0.3); vec3 accum=live; float wsum=1.0; for(int i=0;i<8;i++){float layer=float(i+1); float hB=specHist(i,0.04),hM=specHist(i,0.26),hT=specHist(i,0.50),hA=specHist(i,0.88); vec3 cached=cacheHist(i,tc+orbitField(uv,hB,hM,hT,hA,oldest,layer)).rgb; float w=pow(0.83,layer)*(1.0+hA*1.0+hM*0.5); accum+=cached*acid(layer*0.08+hA*0.6+oldest.r*0.2)*w; wsum+=w;} accum/=wsum; float glow=smoothstep(0.55,1.0,abs(sin(length(uv)*16.0-time_f*1.2+hist*6.0))); accum+=vec3(1.0,0.65,0.3)*glow*(0.04+amp_smooth*0.16); color=vec4(clamp(mix(accum,accum.bgr,smoothstep(0.85,1.0,amp_peak)*0.10),0.0,1.0),1.0);} 