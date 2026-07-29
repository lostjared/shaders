#version 330 core
// Braided loops with interlaced cache echoes.
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
vec3 acid(float t){return 0.5+0.5*cos(TAU*(vec3(0.72,0.94,0.78)*t+vec3(0.08,0.27,0.40)));}
vec4 cacheHist(int i, vec2 uv){if(i==0)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));if(i==1)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));if(i==2)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));if(i==3)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));if(i==4)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));if(i==5)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));if(i==6)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));} 
float specHist(int i,float f){if(i==0)return texture(spectrum0,f).r;if(i==1)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(1)))).r;if(i==2)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(2)))).r;if(i==3)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(3)))).r;if(i==4)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(4)))).r;if(i==5)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(5)))).r;if(i==6)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(6)))).r;return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(7)))).r;}
vec2 knotField(vec2 uv,float bass,float mid,float treble,float air,vec3 oldest,float layer){float weave=sin(uv.x*12.0+time_f*1.4+layer)*cos(uv.y*12.0-time_f*1.8-layer); vec2 dir=vec2(weave,sin(uv.x*7.0-uv.y*9.0+time_f+layer)); dir+=vec2(oldest.g-oldest.r,oldest.b-oldest.g)*0.7; return dir*(0.012+mid*0.025+air*0.020)+vec2(sign(uv.x),-sign(uv.y))*(0.002+bass*0.014);} 
void main(){float aspect=iResolution.x/iResolution.y; vec2 uv=(tc-0.5)*vec2(aspect,1.0); float bass=texture(spectrum0,0.04).r,mid=texture(spectrum0,0.18).r,treble=texture(spectrum0,0.60).r,air=texture(spectrum0,0.88).r; float hist=0.0; for(int i=0;i<8;i++) hist+=specHist(i,0.18); hist/=8.0; vec3 oldest=texture(history, vec3(tc+vec2(cos(time_f*0.18+uv.y*4.0),sin(time_f*0.21+uv.x*5.5))*(0.011+hist*0.027), float(CACHE_HISTORY_LAYER(7)))).rgb; vec3 live=texture(samp,tc+knotField(uv,bass,mid,treble,air,oldest,0.0)).rgb; live=mix(live,live.gbr,0.18+air*0.18)*acid(time_f*0.05+uv.x*0.28+mid); vec3 accum=live; float wsum=1.0; for(int i=0;i<8;i++){float layer=float(i+1); float hB=specHist(i,0.04),hM=specHist(i,0.18),hT=specHist(i,0.60),hA=specHist(i,0.88); vec3 cached=cacheHist(i,tc+knotField(uv,hB,hM,hT,hA,oldest,layer)).rgb; float w=pow(0.81,layer)*(1.0+hM*1.1+hA*0.5); accum+=cached*acid(layer*0.09+hA*0.8)*w; wsum+=w;} accum/=wsum; float weaveGlow=smoothstep(0.35,1.0,abs(cos((uv.x-uv.y)*16.0+time_f*2.1+hist*8.0))); accum+=acid(time_f*0.03+uv.y*0.18)*weaveGlow*(0.06+amp_smooth*0.17); color=vec4(clamp(accum,0.0,1.0),1.0);} 