#version 330 core

in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp; 
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;          
uniform float uamp;         
uniform float iTime;
uniform int iFrame; 
uniform float iTimeDelta;
uniform vec4 iDate;
uniform vec2 iMouseClick;
uniform float iFrameRate;
uniform vec3 iChannelResolution[4];
uniform float iChannelTime[4];
uniform float iSampleRate;

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