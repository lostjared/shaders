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

// Faceted shear trails with crystalline slipping motion.
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
vec3 acid(float t){return 0.5+0.5*cos(TAU*(vec3(0.78,0.92,1.0)*t+vec3(0.03,0.21,0.47)));}
vec4 cacheHist(int i, vec2 uv){if(i==0)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));if(i==1)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));if(i==2)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));if(i==3)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));if(i==4)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));if(i==5)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));if(i==6)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));} 
float specHist(int i,float f){if(i==0)return texture(spectrum0,f).r;if(i==1)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(1)))).r;if(i==2)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(2)))).r;if(i==3)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(3)))).r;if(i==4)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(4)))).r;if(i==5)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(5)))).r;if(i==6)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(6)))).r;return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(7)))).r;}
vec2 shearField(vec2 uv,float bass,float mid,float treble,float air,vec3 oldest,float layer){vec2 dir=vec2(uv.y*0.65+sin(uv.x*10.0+time_f*1.1+layer),uv.x*-0.35+cos(uv.y*14.0-time_f*1.8-layer)); dir+=vec2(oldest.r-oldest.b,oldest.g-0.5); return dir*(0.014+mid*0.030+air*0.016)+vec2(bass*0.02,-treble*0.015);} 
void main(){float aspect=iResolution.x/iResolution.y; vec2 uv=(tc-0.5)*vec2(aspect,1.0); float bass=texture(spectrum0,0.03).r,mid=texture(spectrum0,0.19).r,treble=texture(spectrum0,0.57).r,air=texture(spectrum0,0.87).r; float hist=0.0; for(int i=0;i<8;i++) hist+=specHist(i,0.19); hist/=8.0; vec3 oldest=texture(history, vec3(tc+vec2(cos(time_f*0.20+uv.y*8.0),sin(time_f*0.22+uv.x*8.5))*(0.012+hist*0.028), float(CACHE_HISTORY_LAYER(7)))).rgb; vec3 live=texture(samp,tc+shearField(uv,bass,mid,treble,air,oldest,0.0)).rgb*acid(time_f*0.06+uv.x*0.4+mid); vec3 accum=live; float wsum=1.0; for(int i=0;i<8;i++){float layer=float(i+1); float hB=specHist(i,0.03),hM=specHist(i,0.19),hT=specHist(i,0.57),hA=specHist(i,0.87); vec3 cached=cacheHist(i,tc+shearField(uv,hB,hM,hT,hA,oldest,layer)).rgb; float w=pow(0.80,layer)*(1.0+hM*1.2+hA*0.5); accum+=cached*acid(layer*0.10+hT*0.6)*w; wsum+=w;} accum/=wsum; float edge=smoothstep(0.35,1.0,abs(sin((uv.x-uv.y)*18.0+time_f*2.2+hist*8.0))); accum+=acid(time_f*0.03+uv.y*0.3)*edge*(0.07+amp_smooth*0.18); color=vec4(clamp(accum,0.0,1.0),1.0);} 