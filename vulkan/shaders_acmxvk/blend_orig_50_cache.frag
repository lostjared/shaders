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
#define amp ext.u1.y
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define history_head int(ext.u3.x)
#define iChannelTime ext.custom_uniforms[3].x
#define iFrame int(ext.u2.x)
#define iFrameRate ext.u1.w
#define iMouse ext.mouse
#define iMouseClick ext.mouse.xy
#define iResolution ext.u0.zw
#define iSampleRate ext.u2.z
#define iTime ext.u0.y
#define iTimeDelta ext.u1.x
#define iamp ext.u1.z
#define time_f ext.u2.y
#define time_speed ext.custom_uniforms[3].y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;


layout(set = 0, binding = 0) uniform sampler2D samp; // input video frame texture







uniform vec4 iDate;


uniform vec3 iChannelResolution[4]; // resolution of each texture channel









layout(set = 0, binding = 2) uniform sampler2DArray history;

#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif


void main(void) {
    color = texture(samp, tc);
    vec4 orig = texture(history, vec3(tc, float(CACHE_HISTORY_LAYER(0))));
    color = mix(color, orig, 0.5);
}
    

