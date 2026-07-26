#version 330 core

in vec2 tc;
out vec4 color;

// Live feed and 8-frame cache layers
uniform sampler2D samp;
uniform sampler2D samp1;
uniform sampler2D samp2;
uniform sampler2D samp3;
uniform sampler2D samp4;
uniform sampler2D samp5;
uniform sampler2D samp6;
uniform sampler2D samp7;
uniform sampler2D samp8;

uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

// Helper to fetch history frames
vec4 sampleCache(int idx, vec2 uv) {
    if (idx == 0) return texture(samp, uv);  // Live feed
    if (idx == 1) return texture(samp1, uv); // History frames start here
    if (idx == 2) return texture(samp2, uv);
    if (idx == 3) return texture(samp3, uv);
    if (idx == 4) return texture(samp4, uv);
    if (idx == 5) return texture(samp5, uv);
    if (idx == 6) return texture(samp6, uv);
    if (idx == 7) return texture(samp7, uv);
    return texture(samp8, uv);
}

void main(void) {
    // Determine the center point based on left mouse click
    vec2 center = vec2(0.5, 0.5);
    if (iMouse.z > 0.0) {
        center = iMouse.xy / iResolution.xy;
    }

    float rippleSpeed = 5.0;
    float rippleAmplitude = 0.03;
    float rippleWavelength = 10.0;
    
    // Dynamic twist strength based on vertical mouse position
    float twistStrength = 1.0;
    if (iMouse.z > 0.0 || iMouse.w > 0.0) {
        twistStrength = (iMouse.y / iResolution.y) * 4.0;
    }

    float radius = length(tc - center);
    
    // Base ripple displacement
    float ripple = sin(tc.x * rippleWavelength + time_f * rippleSpeed) * rippleAmplitude;
    ripple += sin(tc.y * rippleWavelength + time_f * rippleSpeed) * rippleAmplitude;
    vec2 rippleTC = tc + vec2(ripple, ripple);
    
    vec4 accum = vec4(0.0);
    float weightSum = 0.0;

    // Loop through the live frame (0) and the 8 cached frames
    for(int i = 0; i <= 8; i++) {
        float gen = float(i);
        
        // The Echo Twist logic
        // We offset the angle based on the historical generation (gen)
        // Older frames get a delayed angle, creating the temporal twist trail
        float echoTwist = twistStrength * (radius - 1.0) + time_f - (gen * 0.2);
        
        float cosA = cos(echoTwist);
        float sinA = sin(echoTwist);
        mat2 rotationMatrix = mat2(cosA, -sinA, sinA, cosA);
        
        // Apply rotation around the dynamic center
        vec2 twistedTC = (rotationMatrix * (rippleTC - center)) + center;
        
        // Sample the correct layer of the temporal cache
        vec4 cached = sampleCache(i, twistedTC);
        
        // Older frames have less weight, causing the echo to fade out smoothly
        float weight = pow(0.75, gen);
        
        accum += cached * weight;
        weightSum += weight;
    }

    // Normalize the accumulated colors
    color = accum / weightSum;
}