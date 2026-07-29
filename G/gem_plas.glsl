#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform float amp;

// Simple hash for noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// Gradient noise for smooth fluid motion
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void main(void) {
    vec2 uv = tc;

    // 1. Create a "Distortion Map" using time and noise
    // This creates the "liquid" flow effect
    float distortX = noise(uv * 4.0 + time_f * 0.5);
    float distortY = noise(uv * 4.0 - time_f * 0.5);
    
    // 2. Offset the texture coordinates
    // 'amp' or a small constant determines how much the image "stretches"
    vec2 warpedUV = uv + vec2(distortX, distortY) * 0.05;

    // 3. Sample the original texture with warped coordinates
    vec4 texColor = texture(samp, warpedUV);

    // 4. "Neon-ify" the colors
    // We boost the saturation and contrast to make the blues/oranges pop
    vec3 neon = pow(texColor.rgb, vec3(1.5)); // Increase contrast
    neon *= vec3(1.2, 1.5, 2.0); // Shift slightly toward electric blue/cyan
    
    // 5. Add a glowing "edge" effect based on the noise
    float glow = smoothstep(0.4, 0.7, distortX) * 0.2;
    neon += glow * vec3(0.0, 0.8, 1.0); // Add a cyan neon shimmer

    color = vec4(neon * (amp + 0.8), 1.0);
}