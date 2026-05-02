#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;

void main(void) {
    vec2 uv = tc;
    vec2 center = vec2(0.5);
    vec2 dragEffect = vec2(0.0);

    if (iMouse.z > 0.0) { // Only when mouse is dragged
        // Convert mouse coordinates to UV space
        vec2 clickPos = iMouse.zw / iResolution.xy;
        vec2 currentPos = iMouse.xy / iResolution.xy;

        // Calculate drag vector components
        vec2 dragVec = currentPos - clickPos;
        float dragStrength = length(dragVec) * 2.0;
        vec2 dragDir = normalize(dragVec + vec2(0.0001));

        // Calculate position relative to click
        vec2 uvOffset = uv - clickPos;
        float distFromClick = length(uvOffset);

        // Create directional distortion components
        float parallel = dot(uvOffset, dragDir);
        float perp = dot(uvOffset, vec2(-dragDir.y, dragDir.x));

        // Apply stretching in drag direction
        parallel *= 1.0 + dragStrength;

        // Add wave effects based on drag direction
        float wave = sin(parallel * 20.0 - dragStrength * 10.0) * 0.02;
        float vortex = tan(perp * 15.0 + dragStrength * 5.0) * 0.01;

        // Combine distortion effects
        dragEffect = vec2(
                         parallel * dragDir.x - perp * dragDir.y,
                         parallel * dragDir.y + perp * dragDir.x) *
                     (1.0 + wave + vortex);

        // Add click-centered bubble effect
        float bubble = smoothstep(0.2, 0.1, distFromClick);
        dragEffect += bubble * dragVec * 0.5;
    }

    // Apply final texture sampling with distortion
    color = texture(samp, uv + dragEffect);
}