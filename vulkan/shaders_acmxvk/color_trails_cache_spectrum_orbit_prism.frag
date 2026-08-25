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

// Prismatic orbit trails with angular splitting and deep-history refraction.
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
vec3 acid(float t){return 0.5+0.5*cos(TAU*(vec3(1.0,0.8,0.55)*t+vec3(0.12,0.30,0.46)));}
vec4 cacheHist(int i, vec2 uv){if(i==0)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));if(i==1)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));if(i==2)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));if(i==3)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));if(i==4)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));if(i==5)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));if(i==6)return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));} 
float specHist(int i,float f){if(i==0)return texture(spectrum0,f).r;if(i==1)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(1)))).r;if(i==2)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(2)))).r;if(i==3)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(3)))).r;if(i==4)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(4)))).r;if(i==5)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(5)))).r;if(i==6)return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(6)))).r;return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(7)))).r;}
vec2 orbitField(vec2 uv,float bass,float mid,float treble,float air,vec3 oldest,float layer){float r=length(uv)+0.001; float a=atan(uv.y,uv.x); float facets=floor(3.0+air*5.0); float q=floor((a+3.14159)/TAU*facets)/facets*TAU; vec2 dir=vec2(cos(q+r*(3.0+bass*6.0)-time_f*(1.2+mid*2.8)-layer*0.4),sin(q-r*(4.0+treble*8.0)+time_f*(1.0+air*2.5)+layer*0.5)); dir+=vec2(oldest.r-oldest.g,oldest.b-oldest.r)*0.8; return dir*(0.012+treble*0.022+air*0.022);} 
void main(){float aspect=iResolution.x/iResolution.y; vec2 uv=(tc-0.5)*vec2(aspect,1.0); float bass=texture(spectrum0,0.02).r,mid=texture(spectrum0,0.24).r,treble=texture(spectrum0,0.62).r,air=texture(spectrum0,0.90).r; float hist=0.0; for(int i=0;i<8;i++) hist+=specHist(i,0.24); hist/=8.0; vec2 oldWarp=vec2(sin(time_f*0.18+uv.y*8.0+hist*7.0),cos(time_f*0.21+uv.x*8.0-hist*6.0))*(0.011+hist*0.030); vec3 oldest=texture(history, vec3(tc+oldWarp, float(CACHE_HISTORY_LAYER(7)))).rgb; vec2 liveWarp=orbitField(uv,bass,mid,treble,air,oldest,0.0); float chroma=0.004+air*0.02; vec3 live=vec3(texture(samp,tc+liveWarp+vec2(chroma,0)).r,texture(samp,tc+liveWarp).g,texture(samp,tc+liveWarp-vec2(chroma,0)).b); live*=acid(time_f*0.08+length(uv)*0.5+air); vec3 accum=live; float wsum=1.0; for(int i=0;i<8;i++){float layer=float(i+1); float hB=specHist(i,0.02),hM=specHist(i,0.24),hT=specHist(i,0.62),hA=specHist(i,0.90); vec3 cached=cacheHist(i,tc+orbitField(uv,hB,hM,hT,hA,oldest,layer)).rgb; vec3 tint=acid(layer*0.11+hA*0.9+time_f*0.03); float w=pow(0.81,layer)*(1.0+hA*1.2+hM*0.6); accum+=mix(cached,cached.bgr,0.18+hT*0.25)*tint*w; wsum+=w;} accum/=wsum; float flash=smoothstep(0.45,1.0,abs(cos(atan(uv.y,uv.x)*6.0-time_f*1.5+hist*8.0))); accum+=acid(uv.y*0.25+time_f*0.05)*flash*(0.06+amp_smooth*0.22); color=vec4(clamp(mix(accum,accum.gbr,smoothstep(0.84,1.0,amp_peak)*0.16),0.0,1.0),1.0);} 