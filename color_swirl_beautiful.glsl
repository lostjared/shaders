#version 330 core

out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float alpha;

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    vec2 uv = (tc * iResolution - 0.5 * iResolution) / iResolution.y;
    
    float t = time_f * 0.5;
    
    // Calculate radius and angle for wave effect
    float radius = length(uv);
    float angle = atan(uv.y, uv.x);
    angle += t;

    // Add ping-pong to create a pulsating effect around the center
    float radMod = pingPong(radius + t * 0.5, 0.5);
    
    // Sine wave for additional distortion and movement
    float wave = sin(radius * 10.0 - t * 5.0) * 0.5 + 0.5;
    
    // Color calculations based on angle and radius with wave effects
    float r = sin(angle * 3.0 + radMod * 10.0 + wave * 6.2831);
    float g = sin(angle * 4.0 - radMod * 8.0  + wave * 4.1230);
    float b = sin(angle * 5.0 + radMod * 12.0 - wave * 3.4560);
    
    // Normalize color values to [0, 1] range and apply a slight mix with texture color
    vec3 col = vec3(r, g, b) * 0.5 + 0.5;
    vec3 texColor = texture(samp, tc).rgb;
    col = mix(col, texColor, 0.3);
    
    // Output the final color with alpha blending
    color = vec4(col, alpha);
}
