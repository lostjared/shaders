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
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;




const float PI = 3.1415926535897932384626433832795;

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    float zoomPhase = time_f * 0.12;
    float zLocal = fract(zoomPhase);
    float tri = 1.0 - abs(zLocal * 2.0 - 1.0);

    float minZoom = 0.3;
    float maxZoom = 4.0;
    float zoom = mix(minZoom, maxZoom, tri);

    vec2 z = tc - m;
    z.x *= aspect;
    z /= zoom;
    z.x /= aspect;
    vec2 zoomTC = fract(z + m);

    vec4 baseTex = texture(samp, zoomTC);
    color = baseTex;
}
