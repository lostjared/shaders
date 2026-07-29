#version 330 core
// Spindle-like knots spinning inward through layered history.
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
vec3 acid(float t){return 0.5+0.5*cos(TAU*(vec3(0.82,0.74,1.0)*t+vec3(0.10,0.19,0.37)));}
vec4 cacheHist(int i, vec2 uv){if(i==0)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));if(i==1)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));if(i==2)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));if(i==3)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));if(i==4)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));if(i==5)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));if(i==6)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));} 
float specHist(int i,float f){if(i==0)return texture(spectrum0,f).r;if(i==1)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(1)))).r;if(i==2)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(2)))).r;if(i==3)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(3)))).r;if(i==4)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(4)))).r;if(i==5)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(5)))).r;if(i==6)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(6)))).r;return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(7)))).r;}
vec2 knotField(vec2 uv,float bass,float mid,float treble,float air,vec3 oldest,float layer){float r=length(uv)+0.001; float a=atan(uv.y,uv.x); vec2 dir=vec2(cos(a*3.0-r*(6.0+treble*8.0)-time_f*(1.0+mid*1.4)-layer),sin(a*2.0+r*(5.0+bass*6.0)+time_f*(0.9+air*1.2)+layer)); dir+=vec2(oldest.g-oldest.b,oldest.r-oldest.g)*0.75; return dir*(0.010+mid*0.024+treble*0.015)-uv*(0.003+bass*0.014);} 
void main(){float aspect=iResolution.x/iResolution.y; vec2 uv=(tc-0.5)*vec2(aspect,1.0); float bass=texture(spectrum0,0.02).r,mid=texture(spectrum0,0.20).r,treble=texture(spectrum0,0.56).r,air=texture(spectrum0,0.84).r; float hist=0.0; for(int i=0;i<8;i++) hist+=specHist(i,0.56); hist/=8.0; vec3 oldest=texture(history, vec3(tc+vec2(sin(time_f*0.22+uv.y*6.0),cos(time_f*0.24+uv.x*6.0))*(0.011+hist*0.027), float(CACHE_HISTORY_LAYER(7)))).rgb; vec3 live=texture(samp,tc+knotField(uv,bass,mid,treble,air,oldest,0.0)).rgb*acid(time_f*0.06+length(uv)*0.45+treble); vec3 accum=live; float wsum=1.0; for(int i=0;i<8;i++){float layer=float(i+1); float hB=specHist(i,0.02),hM=specHist(i,0.20),hT=specHist(i,0.56),hA=specHist(i,0.84); vec3 cached=cacheHist(i,tc+knotField(uv,hB,hM,hT,hA,oldest,layer)).rgb; float w=pow(0.80,layer)*(1.0+hT*1.1+hB*0.4); accum+=cached*acid(layer*0.10+hT*0.7+oldest.b*0.2)*w; wsum+=w;} accum/=wsum; float spindle=smoothstep(0.45,1.0,abs(cos(length(uv)*24.0-time_f*1.7+hist*9.0))); accum+=acid(time_f*0.03+uv.y*0.18)*spindle*(0.05+amp_smooth*0.17); color=vec4(clamp(accum,0.0,1.0),1.0);} 