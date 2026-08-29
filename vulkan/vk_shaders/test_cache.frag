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
#define history_head int(ext.u3.x)
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;
layout(set = 0, binding = 2) uniform sampler2DArray history;

#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif





vec3 rainbowGradient(float t) {
    float r = 0.5 + 0.5 * cos(6.2831 * (t + 0.0) + 0.0);
    float g = 0.5 + 0.5 * cos(6.2831 * (t + 0.3) + 2.0);
    float b = 0.5 + 0.5 * cos(6.2831 * (t + 0.6) + 4.0);
    return vec3(r, g, b);
}

void main(void) {
    // Dynamic UV distortion
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / iResolution.y;
    float len = length(p);
    
    // Distortion based on sine waves
    vec2 distortedTC = tc + vec2(
        sin(time_f * 0.5 + tc.y * 8.0) * 0.03 * amp,
        cos(time_f * 0.4 + tc.x * 10.0) * 0.03 * uamp
    );

    // Sample textures with modulation
    vec4 tex1 = texture(history, vec3(distortedTC, float(CACHE_HISTORY_LAYER(0))));
    vec4 tex2 = texture(history, vec3(distortedTC * 1.2, float(CACHE_HISTORY_LAYER(1))));
    vec4 tex3 = texture(history, vec3(tc * 0.8 + tex1.xy * 0.05, float(CACHE_HISTORY_LAYER(2))));
    vec4 tex4 = texture(history, vec3(tc * 1.1 - tex2.xy * 0.03, float(CACHE_HISTORY_LAYER(3))));
    vec4 baseTex = texture(samp, distortedTC);

    // Energy effect with radial waves
    float energyWave = sin(len * 8.0 - time_f * 3.0) * 0.5 + 0.5;
    
    // Generate the rainbow gradient based on time and coordinates
    vec3 energyColor = rainbowGradient(tc.x + tc.y + time_f * 0.2);
    energyColor = mix(energyColor, vec3(1.0, 0.2, 0.8), energyWave);  // Add pinkish hue

    // Combine textures with blending and energy effect
    vec3 finalColor = mix(tex1.rgb, tex2.rgb, 0.5) * 0.8 
                    + tex3.rgb * 0.4 
                    + tex4.rgb * 0.3 
                    + energyColor * 0.5;

    // Mouse interaction effect (hover glow)
    float mouseDist = length(tc - iMouse.xy / iResolution);
    finalColor += smoothstep(0.2, 0.0, mouseDist) * vec3(0.8, 0.4, 1.0);

    // Output the final color
    color = vec4(finalColor * baseTex.rgb, 1.0);
}
