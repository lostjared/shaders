#version 330 core

out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

// Normalizes the color palette by reducing the depth per channel
vec3 NormalizePalette(vec3 col, float levels) {
    // Scales 0.0-1.0 to 0.0-levels, rounds it, then scales back
    // This creates discrete color steps without shifting the base hue
    return floor(col * levels + 0.5) / levels;
}

void main(void) {
    // Resolution crunch (NES internal resolution)
    vec2 pixelSize = vec2(256.0, 240.0);
    vec2 coord = floor(tc * pixelSize) / pixelSize;
    
    vec4 texColor = texture(samp, coord);
    
    // Applying a 4-level or 8-level posterization 
    // This keeps colors "normal" but removes the smooth gradients
    vec3 quantizedColor = NormalizePalette(texColor.rgb, 6.0);
    
    color = vec4(quantizedColor, texColor.a);
}