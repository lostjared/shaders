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

// Soft velvet knots with slower, plush trail folding.
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
vec3 acid(float t){return 0.5+0.5*cos(TAU*(vec3(0.66,0.54,0.92)*t+vec3(0.18,0.10,0.39)));}
vec4 cacheHist(int i, vec2 uv){if(i==0)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));if(i==1)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));if(i==2)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));if(i==3)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));if(i==4)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));if(i==5)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));if(i==6)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));} 
float specHist(int i,float f){if(i==0)return texture(spectrum0,f).r;if(i==1)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(1)))).r;if(i==2)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(2)))).r;if(i==3)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(3)))).r;if(i==4)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(4)))).r;if(i==5)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(5)))).r;if(i==6)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(6)))).r;return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(7)))).r;}
vec2 knotField(vec2 uv,float bass,float mid,float treble,float air,vec3 oldest,float layer){vec2 dir=vec2(sin(uv.x*6.0+time_f*0.8+layer),cos(uv.y*7.0-time_f*0.9-layer)); dir+=vec2(sin((uv.x+uv.y)*4.0),cos((uv.x-uv.y)*4.0))*0.5; dir+=vec2(oldest.r-oldest.b,oldest.g-oldest.r)*0.6; return dir*(0.010+mid*0.022+air*0.018);} 
void main(){float aspect=iResolution.x/iResolution.y; vec2 uv=(tc-0.5)*vec2(aspect,1.0); float bass=texture(spectrum0,0.05).r,mid=texture(spectrum0,0.26).r,treble=texture(spectrum0,0.48).r,air=texture(spectrum0,0.80).r; float hist=0.0; for(int i=0;i<8;i++) hist+=specHist(i,0.26); hist/=8.0; vec3 oldest=texture(history, vec3(tc+vec2(cos(time_f*0.14+uv.y*4.0),sin(time_f*0.16+uv.x*4.0))*(0.010+hist*0.024), float(CACHE_HISTORY_LAYER(7)))).rgb; vec3 live=texture(samp,tc+knotField(uv,bass,mid,treble,air,oldest,0.0)).rgb*acid(time_f*0.04+length(uv)*0.3+mid); vec3 accum=live; float wsum=1.0; for(int i=0;i<8;i++){float layer=float(i+1); float hB=specHist(i,0.05),hM=specHist(i,0.26),hT=specHist(i,0.48),hA=specHist(i,0.80); vec3 cached=cacheHist(i,tc+knotField(uv,hB,hM,hT,hA,oldest,layer)).rgb; float w=pow(0.84,layer)*(1.0+hM*0.9+hA*0.4); accum+=cached*acid(layer*0.07+hM*0.7)*w; wsum+=w;} accum/=wsum; float plush=smoothstep(0.4,1.0,abs(sin((uv.x*10.0)*(uv.y*2.0)-time_f*1.2+hist*6.0))); accum+=acid(time_f*0.02+uv.x*0.14)*plush*(0.04+amp_smooth*0.14); color=vec4(clamp(accum,0.0,1.0),1.0);} 