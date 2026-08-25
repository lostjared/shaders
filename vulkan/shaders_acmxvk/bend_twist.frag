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
#define iChannelTime ext.custom_uniforms[3].x
#define iFrame int(ext.u2.x)
#define iFrameRate ext.u1.w
#define iMouse ext.mouse
#define iMouseClick ext.mouse.xy
#define iResolution ext.u0.zw
#define iSampleRate ext.u2.z
#define iTime ext.u0.y
#define iTimeDelta ext.u1.x
#define time_f ext.u2.y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp; 







uniform vec4 iDate;


uniform vec3 iChannelResolution[4];



void main(void) {
    vec2 uv = tc - 0.5;

    float aspect = iResolution.x / iResolution.y;
    uv.x *= aspect;

    float dist = length(uv);
    
    float twistStrength = (time_f * 10.0); 
    float angle = amp + (dist * twistStrength);

    float s = sin(angle);
    float c = cos(angle);
    
    vec2 twistedUV = vec2(
        uv.x * c - uv.y * s,
        uv.x * s + uv.y * c
    );

    float bendStrength = (time_f * uamp * 0.5); 
    twistedUV.x += sin(twistedUV.y * 10.0 + time_f) * bendStrength;

    twistedUV.x /= aspect;
    vec2 finalUV = twistedUV + 0.5;

    color = texture(samp, finalUV);
}