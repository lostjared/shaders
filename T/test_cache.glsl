#version 330 core

in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp;
uniform sampler2D samp1; // cache texture 0
uniform sampler2D samp2; // cache texture 1
uniform sampler2D samp3;
uniform sampler2D samp4;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;

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
    vec4 tex1 = texture(samp1, distortedTC);
    vec4 tex2 = texture(samp2, distortedTC * 1.2);
    vec4 tex3 = texture(samp3, tc * 0.8 + tex1.xy * 0.05);
    vec4 tex4 = texture(samp4, tc * 1.1 - tex2.xy * 0.03);
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
