#version 330

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

const float PI = 3.14159;

// Helper to convert Hue to RGB
vec3 rainbow(float t) {
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

void main(void) {
    // 1. Center UVs to -1.0 to 1.0
    vec2 uv = tc * 2.0 - 1.0;
    
    // 2. Correct Aspect Ratio (assuming landscape)
    // This prevents the spiral from looking like an oval
    if (iResolution.x != 0.0) {
        uv.y *= iResolution.y / iResolution.x;
    }

    // 3. Create the Wave Distortion
    // Shifts the y-lookup based on x-position and time
    float wave = sin(uv.x * 10.0 + time_f * 2.0) * 0.1;

    // 4. Calculate Polar Angle
    // atan(y, x) gives the angle. We add time to rotate it.
    float angle = atan(uv.y + wave, uv.x) + time_f * 2.0;

    // 5. Generate Rainbow
    // Normalize angle from -PI..PI to 0..1 for the rainbow function
    vec3 rainbow_color = rainbow(angle / (2.0 * PI));

    // 6. Sample Background Texture
    vec4 original_color = texture(samp, tc);

    // 7. Blend
    vec3 blended_color = mix(original_color.rgb, rainbow_color, 0.5);

    // 8. Output (FIXED)
    // Replaced the strobing sin() with a gentle pulse effect
    // This pulses the brightness between 0.5 and 1.0
    float pulse = 0.75 + 0.25 * sin(time_f * 2.0); 
    
    color = vec4(blended_color * pulse, original_color.a);
}