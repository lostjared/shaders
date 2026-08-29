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



vec3 rainbow(vec2 uv, float offset) {
    float rainbowFactor = sin(offset + uv.x * 10.0) * 0.5 + 0.5;
    return vec3(
        sin(rainbowFactor * 3.0 + 0.0),
        sin(rainbowFactor * 3.0 + 2.0),
        sin(rainbowFactor * 3.0 + 4.0)
    );
}

void main(void) {
    vec4 texColor = texture(samp, tc);
    
    float phase = mod(time_f, 6.0);
    float t = fract(time_f / 2.0);
    vec2 uv = tc;
    vec3 rainbowColor;

    float angle = mix(0.0, 6.28318, t);


    uv += vec2(sin(angle + length(uv) * 10.0), cos(angle + length(uv) * 10.0)) * 0.1;
    
    
    rainbowColor = rainbow(uv, time_f);
    
    color = vec4(texColor.rgb + rainbowColor * 0.5, texColor.a);
}
