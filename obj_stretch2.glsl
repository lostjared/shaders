#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;

void main(void) {
    // Convert coordinates to [0,1] range
    vec2 currentPos = iMouse.xy / iResolution;
    // Current mouse position
    vec2 clickPos = iMouse.zw / iResolution;    
    // Initial click position

    if (iMouse.z > 0.0) { // Only when dragging
        vec2 drag = currentPos - clickPos;
        float dist = distance(tc, clickPos);
        
        float radius = 0.3;
        float strength = 0.5;
        float falloff = 1.0 - smoothstep(0.0, radius, dist);
        
        // Reverse direction by SUBTRACTING the displacement
        vec2 deformedUV = tc - (drag * falloff * strength);
        color = texture(samp, deformedUV);
    } else {
        color = texture(samp, tc);
    }
}