#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    // Normalize mouse coordinates
    vec2 mouse = iMouse.xy / iResolution.xy;
    vec2 prevMouse = iMouse.zw / iResolution.xy;
    
    // Calculate mouse movement direction and speed
    vec2 mouseDelta = mouse - prevMouse;
    float mouseSpeed = length(mouseDelta);
    mouseDelta = normalize(mouseDelta + 0.000001); // Prevent division by zero
    
    // Calculate distance from fragment to mouse
    float dist = length(mouse - tc);
    
    // Create exponential falloff influence
    float influence = exp(-dist * 2.0); // Increased density for stronger local effect
    influence *= mouseSpeed; // Scale by movement speed
    
    // Base displacement from mouse movement
    vec2 displacement = mouseDelta * influence * 0.15; // Increased displacement strength
    
    // Add fluid-like turbulence using time-based noise
    displacement += 0.03 * vec2(
        sin(time_f * 4.0 + tc.y * 12.0),
        cos(time_f * 4.0 + tc.x * 12.0)
    ) * influence;
 
   
    // Apply displacement to texture coordinates
    vec2 displacedTc = tc + sin(displacement * pingPong(time_f, 7.0));
    
    // Sample texture with distorted coordinates
    color = texture(samp, displacedTc);
}