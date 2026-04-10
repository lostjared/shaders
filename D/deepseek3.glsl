#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.333, 0.666)));
}

vec4 waveEffect(vec2 uv, vec4 original) {
    // Horizontal wave parameters
    float hSpeed = 1.5;
    float hFreq = 2.0;
    float hTime = pingPong(time_f * hSpeed, 2.0);
    
    // Vertical wave parameters
    float vSpeed = 1.2;
    float vFreq = 1.5;
    float vTime = pingPong(time_f * vSpeed, 2.0);
    
    // Diagonal wave parameters
    float dSpeed = 2.0;
    float dFreq = 3.0;
    float dTime = pingPong(time_f * dSpeed, 2.0);

    // Create multiple wave patterns
    float wave1 = sin((uv.x * hFreq + hTime) * 6.28318);
    float wave2 = sin((uv.y * vFreq + vTime) * 6.28318);
    float wave3 = sin((uv.x + uv.y) * dFreq + dTime * 3.14159);
    
    // Combine wave patterns
    float combinedWave = (wave1 + wave2 + wave3) / 3.0;
    
    // Create color gradient based on wave position
    vec3 waveColor = rainbow(combinedWave * 0.5 + 0.5);
    
    // Create pulsing alpha based on wave intensity
    float waveAlpha = smoothstep(0.3, 0.7, abs(combinedWave));
    
    // Create moving wave lines
    float travelingWave = 
        sin(uv.x * 20.0 + time_f * 5.0) * 
        sin(uv.y * 20.0 - time_f * 3.0) * 
        sin(time_f * 2.0);
    
    // Mix original texture with wave colors
    vec4 finalColor = original;
    finalColor.rgb = mix(
        finalColor.rgb,
        waveColor * (1.0 + travelingWave * 0.5),
        waveAlpha * 0.7
    );
    
    // Add edge glow
    float edgeGlow = smoothstep(0.8, 0.0, length(uv - 0.5));
    finalColor.rgb += waveColor * edgeGlow * 0.3;
    
    return finalColor;
}

void main(void) {
    vec2 uv = tc;
    
    // Create texture distortion waves
    vec2 offset = vec2(
        sin(time_f + uv.y * 5.0) * 0.02,
        cos(time_f * 0.8 + uv.x * 4.0) * 0.02
    );
    
    // Get original texture color
    vec4 original = texture(samp, uv + offset);
    
    // Apply wave effects
    color = waveEffect(uv, original);
    
    // Add chromatic aberration
    color.r = texture(samp, uv + offset * 0.3).r;
    color.b = texture(samp, uv - offset * 0.3).b;

    color = sin(color * pingPong(time_f, 10.0));    

    // Maintain alpha
    color.a = original.a;
}