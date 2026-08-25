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
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
	  	vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    uv = uv - floor(uv);    
    vec2 normCoord = (uv * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);
    float dist = length(normCoord);
    float maxRippleRadius = 25.0;
    float rippleSpeed = 2.0 * pingPong(time_f, 10.0);
    float phase = mod(time_f * rippleSpeed, maxRippleRadius);
    float ripple = sin((dist - phase) * 10.0) * exp(-dist * 3.0);
    vec2 displacedCoord = vec2(tc.x, tc.y + ripple * sin(time_f));
    color = texture(samp, displacedCoord);
}
