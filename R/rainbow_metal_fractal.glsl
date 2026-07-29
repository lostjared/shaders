#version 330 core
in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;

// High-fidelity spectrum for the oily "fringe" colors
vec3 spectrum(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67))));
}

// Simple fractal noise function
float fractalNoise(vec2 uv) {
    float t = time_f * 0.1;
    float n = 0.0;
    float a = 1.0;
    for (int i = 0; i < 5; ++i) {
        n += a * texture(samp, uv).r;
        uv = fract(uv * 2.0); // Scale and wrap coordinates to create fractal pattern
        a *= 0.5; // Decrease amplitude for each iteration
    }
    return n / (1 - 0.5); // Normalize the noise value
}

void main(void) {
    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Add some fractal noise to the ripple calculation for more complex patterns
    float noiseValue = fractalNoise(tc * 5.0) * 0.1;
    float ripple = sin(angle * 10.0 + time_f + noiseValue) * 0.03;
    ripple += sin(angle * 25.0 - time_f * 2.0) * 0.01; // Secondary fine detail
    
    float wave = sin(r * 20.0 - time_f * 4.0 + ripple * 10.0);
    
    float shift = ripple * 0.5 + wave * 0.01;
    
    float r_chan = texture(samp, tc + vec2(shift, 0.0)).r;
    float g_chan = texture(samp, tc).g;
    float b_chan = texture(samp, tc - vec2(shift, 0.0)).b;
    vec3 baseTex = vec3(r_chan, g_chan, b_chan);

    // Psychedelic Coloring with more vibrant and complex colors based on fractal noise
    vec3 rainbow = spectrum(r - time_f * 0.5 + ripple + noiseValue * 0.2);
    float glowMask = smoothstep(0.5, 1.0, wave);
    
    // Central Highlight with increased brightness and saturation
    vec3 coreGlow = vec3(1.0, 0.98, 0.9) * pow(wave, 2.0) * 2.0;

    vec3 finalColor = mix(baseTex, rainbow, glowMask * 0.35);
    finalColor = finalColor * sin(coreGlow * time_f);
    
    // Add a bit of metallic "sheen" to the edges of the ripples
    finalColor += (wave * ripple * 2.0) + noiseValue * 0.1;

    color = vec4(finalColor, 1.0);
}