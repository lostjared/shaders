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
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;


void main(void) {
    // Flip texture coordinates upside down
    vec2 uv = vec2(tc.x, 1.0 - tc.y);
    
    // Center coordinates and calculate polar form
    vec2 centeredUV = uv - 0.5;
    float radius = length(centeredUV);
    float angle = atan(centeredUV.y, centeredUV.x);
    
    // Tornado spiral effect with time
    float spiralStrength = 10.0;
    float spiralFactor = radius * spiralStrength + time_f * 2.0;
    angle += spiralFactor;
    
    // Create vertical tornado stretching
    float verticalStretch = radius * 0.5;
    radius = pow(radius, 0.9);
    
    // Convert back to Cartesian coordinates
    vec2 distorted = vec2(cos(angle), sin(angle)) * radius;
    distorted.y -= verticalStretch;
    
    // Tear drop effect (stronger at top)
    float tearShape = pow(uv.y, 2.0);
    distorted.y -= tearShape * 0.3;
    
    // Ice cube refraction effect
    float iceRefract = sin(distorted.x * 50.0 + time_f * 4.0) * 0.01;
    iceRefract += cos(distorted.y * 40.0 + time_f * 3.0) * 0.01;
    distorted += iceRefract * tearShape;
    
    // Final UV adjustment
    distorted += 0.5;
    
    // RGB channel separation
    float colorSplit = 0.02;
    vec4 r = texture(samp, distorted + vec2(-colorSplit, 0.0));
    vec4 g = texture(samp, distorted);
    vec4 b = texture(samp, distorted + vec2(colorSplit, 0.0));
    
    // Combine channels with fading edges
    float edgeFade = 1.0 - smoothstep(0.4, 0.5, radius);
    color = vec4(r.r, g.g, b.b, 1.0);
}