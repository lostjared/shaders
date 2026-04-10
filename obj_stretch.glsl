#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;

void main(void) {
    // Convert mouse positions to texture space (0-1)
    vec2 mouseUV = iMouse.xy / iResolution.xy;
    vec2 clickUV = iMouse.zw / iResolution.xy;
    vec2 drag = mouseUV - clickUV;
    
    // Calculate distance from current pixel to click position
    float dist = distance(tc, clickUV);
    
    // Calculate falloff using smoothstep for better control
    float radius = uamp;
    float falloff = 1.0 - smoothstep(0.0, radius, dist);
    
    // Apply displacement with amplitude control
    vec2 displacedTC = tc + drag * falloff * time_f;
    
    // Sample texture with displaced coordinates
    color = texture(samp, displacedTC);
}