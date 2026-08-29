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
#define amp ext.u1.y
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;                  // Texcoords passed from vertex shader
layout(location = 0) out vec4 color;              // Final color output of the fragment

layout(set = 0, binding = 0) uniform sampler2D samp;      // The texture we're sampling





// Swirl function for more controlled “twisting”
vec2 swirl(vec2 uv, float centerRadius, float swirlAmount) {
    float r = length(uv);
    float a = atan(uv.y, uv.x);
    // The 'f' blend factor makes the swirl die off outside 'centerRadius'
    float f = smoothstep(centerRadius, 0.0, r);
    a += swirlAmount * f;
    return r * vec2(cos(a), sin(a));
}

// Ping-pong function, just in case you still need it
float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

// Helper to make a rainbow color.  t in [0..1] loops the hue.
vec3 rainbow(float t) {
    // Shift phases by 120° (2π/3 = 2.0943951)
    return vec3(
       sin(2.0 * 3.14159 * t),
       sin(2.0 * 3.14159 * t + 2.0943951),
       sin(2.0 * 3.14159 * t + 4.18879)
    ) * 0.5 + 0.5; // Remap from [-1,1] to [0,1]
}

void main(void)
{
    // Combine your amplitude inputs (adjust to taste)
    float A = uamp * amp / time_f;

    // Normalized device coordinates in range [-1, +1]
    vec2 uv = tc * 2.0 - 1.0;
    float aspect = iResolution.x / iResolution.y;
    uv.x *= aspect;

    // Add swirling based on time and amplitude
    uv = swirl(uv, 0.8, 2.0 * A * sin(time_f * 0.5));

    // Convert back to [0,1] range for sampling
    uv.x /= aspect;
    uv = uv * 0.5 + 0.5;

    // Read the base texture
    vec4 baseColor = texture(samp, uv);

    //------------------------------------------------------
    // Create a time-varying, rainbow-like color
    //------------------------------------------------------
    // Use uv, time, and amplitude to drive the hue
    float rainbowFactor = time_f * 0.2 + uv.x + uv.y + A * 2.0;
    vec3 rainbowColor   = rainbow(fract(rainbowFactor));

    // Mix the texture color with a bright rainbow
    // Increase or decrease the mix factor to taste
    baseColor.rgb = mix(baseColor.rgb, rainbowColor, 0.75);

    //------------------------------------------------------
    // Optional: Additional kaleidoscopic swirl
    //------------------------------------------------------
    uv = swirl(uv - 0.5, 1.0, A * 10.0) + 0.5;
    baseColor *= texture(samp, uv);

    //------------------------------------------------------
    // Final output
    //------------------------------------------------------
    // Instead of sin(...), directly output the bright color
    // (Using pingPong just in case you still want amplitude bouncing)
    float t_amp = pingPong(amp, 8.0) + 1.0;
    baseColor.rgb *= (t_amp + uamp);

    // Make sure we clamp if you prefer not to blow out highlights
    baseColor = clamp(baseColor, 0.0, 1.0);

    float time_t = pingPong(time_f, 6.0) + 1.0;

    color = sin(baseColor * time_t);
    color.a = 1.0; 
}
