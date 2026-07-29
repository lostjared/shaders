#version 330 core
// Mirage shears with soft heat-haze drift across the cached frames.
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
vec3 acid(float t){return 0.5+0.5*cos(TAU*(vec3(1.0,0.74,0.48)*t+vec3(0.05,0.20,0.39)));}
vec4 cacheHist(int i, vec2 uv){if(i==0)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));if(i==1)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));if(i==2)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));if(i==3)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));if(i==4)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));if(i==5)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));if(i==6)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));} 
float specHist(int i,float f){if(i==0)return texture(spectrum0,f).r;if(i==1)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(1)))).r;if(i==2)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(2)))).r;if(i==3)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(3)))).r;if(i==4)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(4)))).r;if(i==5)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(5)))).r;if(i==6)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(6)))).r;return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(7)))).r;}
vec2 shearField(vec2 uv,float bass,float mid,float treble,float air,vec3 oldest,float layer){vec2 dir=vec2(sin(uv.y*10.0+time_f*1.2+layer),cos(uv.x*9.0-time_f*1.0-layer)); dir+=vec2(uv.y*0.25,-uv.x*0.20); dir+=vec2(oldest.g-oldest.b,oldest.r-oldest.g)*0.7; return dir*(0.012+mid*0.026+air*0.022);} 
void main(){float aspect=iResolution.x/iResolution.y; vec2 uv=(tc-0.5)*vec2(aspect,1.0); float bass=texture(spectrum0,0.04).r,mid=texture(spectrum0,0.28).r,treble=texture(spectrum0,0.52).r,air=texture(spectrum0,0.86).r; float hist=0.0; for(int i=0;i<8;i++) hist+=specHist(i,0.28); hist/=8.0; vec3 oldest=texture(history, vec3(tc+vec2(cos(time_f*0.12+uv.y*6.0),sin(time_f*0.14+uv.x*6.5))*(0.011+hist*0.026), float(CACHE_HISTORY_LAYER(7)))).rgb; vec3 live=texture(samp,tc+shearField(uv,bass,mid,treble,air,oldest,0.0)).rgb; live=mix(live,live.bgr,0.15+air*0.20)*acid(time_f*0.04+uv.y*0.22+mid); vec3 accum=live; float wsum=1.0; for(int i=0;i<8;i++){float layer=float(i+1); float hB=specHist(i,0.04),hM=specHist(i,0.28),hT=specHist(i,0.52),hA=specHist(i,0.86); vec3 cached=cacheHist(i,tc+shearField(uv,hB,hM,hT,hA,oldest,layer)).rgb; float w=pow(0.81,layer)*(1.0+hM*1.0+hA*0.7); accum+=cached*acid(layer*0.09+hA*0.7+time_f*0.02)*w; wsum+=w;} accum/=wsum; float haze=smoothstep(0.35,1.0,abs(cos(uv.y*26.0-time_f*2.1+hist*8.0))); accum+=acid(time_f*0.03+uv.x*0.2)*haze*(0.05+amp_smooth*0.16); color=vec4(clamp(accum,0.0,1.0),1.0);} 