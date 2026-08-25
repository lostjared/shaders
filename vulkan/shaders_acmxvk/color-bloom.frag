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



void main(void) {
    vec2 uv = tc * iResolution / vec2(iResolution.y);
    float time = time_f * 0.5;
    float angle = time;
    vec2 center = vec2(0.5, 0.5) * iResolution / vec2(iResolution.y);
    vec2 toCenter = uv - center;
    float radius = length(toCenter);
    float theta = atan(toCenter.y, toCenter.x) + time;
    float pattern = abs(sin(12.0 * theta) * cos(12.0 * radius));
    
    // Sample the texture at the current UV coordinates
    vec4 texColor = texture(samp, tc);
    
    // Determine the brightness of the pixel
    float brightness = dot(texColor.rgb, vec3(0.299, 0.587, 0.114));
    
    // Apply a simple threshold for bright pixels to determine blooming effect
    float bloomThreshold = 0.6; // You can adjust this value to control the sensitivity of the bloom
    vec3 bloomColor = texColor.rgb * pattern;
    vec3 finalColor = mix(texColor.rgb, bloomColor, smoothstep(bloomThreshold - 0.1, bloomThreshold + 0.1, brightness)).rgb;
    
    // Output the final color
    color = vec4(finalColor, texColor.a);
}
