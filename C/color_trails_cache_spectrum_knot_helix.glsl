#version 330 core
// Twisting helix trails woven from cache history.
in vec2 tc; out vec4 color;
uniform sampler2D samp;
uniform sampler2DArray history;
uniform int history_head;
#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif
uniform sampler1D spectrum0;
uniform sampler1DArray spectrum_history;
uniform int spectrum_history_head;
uniform int spectrum_history_size;
#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif
uniform float time_f,amp_peak,amp_smooth; uniform vec2 iResolution;
const float TAU=6.28318530718;
vec3 acid(float t){return 0.5+0.5*cos(TAU*(vec3(0.86,0.68,1.0)*t+vec3(0.11,0.24,0.42)));}
vec4 cacheHist(int i, vec2 uv){if(i==0)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));if(i==1)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));if(i==2)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));if(i==3)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));if(i==4)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));if(i==5)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));if(i==6)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));} 
float specHist(int i,float f){if(i==0)return texture(spectrum0,f).r;if(i==1)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(1)))).r;if(i==2)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(2)))).r;if(i==3)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(3)))).r;if(i==4)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(4)))).r;if(i==5)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(5)))).r;if(i==6)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(6)))).r;return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(7)))).r;}
vec2 knotField(vec2 uv,float bass,float mid,float treble,float air,vec3 oldest,float layer){float a=sin((uv.x+uv.y)*8.0+time_f*1.3+layer); float b=cos((uv.x-uv.y)*10.0-time_f*1.7-layer); vec2 dir=vec2(a-b,b+a); dir+=vec2(oldest.b-oldest.r,oldest.g-oldest.b)*0.8; return dir*(0.010+mid*0.028+treble*0.016)+vec2(uv.y,-uv.x)*(0.003+air*0.016);} 
void main(){float aspect=iResolution.x/iResolution.y; vec2 uv=(tc-0.5)*vec2(aspect,1.0); float bass=texture(spectrum0,0.03).r,mid=texture(spectrum0,0.22).r,treble=texture(spectrum0,0.55).r,air=texture(spectrum0,0.83).r; float hist=0.0; for(int i=0;i<8;i++) hist+=specHist(i,0.55); hist/=8.0; vec3 oldest=texture(history, vec3(tc+vec2(sin(time_f*0.20+uv.y*5.0),cos(time_f*0.26+uv.x*5.0))*(0.012+hist*0.028), float(CACHE_HISTORY_LAYER(7)))).rgb; vec3 live=texture(samp,tc+knotField(uv,bass,mid,treble,air,oldest,0.0)).rgb*acid(time_f*0.07+length(uv)*0.4+treble); vec3 accum=live; float wsum=1.0; for(int i=0;i<8;i++){float layer=float(i+1); float hB=specHist(i,0.03),hM=specHist(i,0.22),hT=specHist(i,0.55),hA=specHist(i,0.83); vec3 cached=cacheHist(i,tc+knotField(uv,hB,hM,hT,hA,oldest,layer)).rgb; float w=pow(0.80,layer)*(1.0+hT*1.2+hA*0.4); accum+=cached*acid(layer*0.10+hT*0.7)*w; wsum+=w;} accum/=wsum; float braid=smoothstep(0.4,1.0,abs(sin((uv.x+uv.y)*18.0-time_f*2.0+hist*9.0))); accum+=acid(time_f*0.04+uv.y*0.25)*braid*(0.06+amp_smooth*0.18); color=vec4(clamp(accum,0.0,1.0),1.0);} 