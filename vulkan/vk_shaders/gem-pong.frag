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

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



// Standard Ping-Pong function
float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

// Neon Palette Generator
vec3 neonGradient(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

void main(void) {
    // 1. Center and Aspect Ratio
    vec2 uv = (tc * 2.0 - 1.0);
    float aspect = iResolution.x / iResolution.y;
    uv.x *= aspect;

    // 2. Sphere Projection
    float d = length(uv);
    float radius = 0.85; // Sphere boundary
    
    // Mask for the sphere shape
    float mask = smoothstep(radius, radius - 0.01, d);
    
    // Calculate Sphere Depth (Z) and Spherical UVs
    float z = sqrt(max(0.0, radius * radius - d * d));
    vec3 normal = normalize(vec3(uv, z));
    
    // 3. Spiral Animation Logic (Ping-Ponging)
    // T1 oscillates the rotation speed
    float t1 = pingPong(time_f * 0.4, 4.0);
    // T2 oscillates the spiral tightness
    float t2 = pingPong(time_f * 0.2, 5.0) - 2.5;

    float angle = atan(uv.y, uv.x);
    // The "Spiral" factor: combining angle, radius, and oscillating time
    float spiral = angle + (t2 * log(d + 0.1)) + t1;

    // 4. Color and Strobing
    vec3 spiralColor = neonGradient(spiral * 0.5);
    
    // Add some "shading" to make it look like a sphere
    float diffuse = max(dot(normal, normalize(vec3(1.0, 1.0, 1.0))), 0.0);
    float specular = pow(max(dot(reflect(vec3(-0.5, -0.5, -1.0), normal), vec3(0,0,1)), 0.0), 20.0);

    // 5. Sampling the original texture with a "Ping-Pong" blur effect
    float blurAmt = pingPong(time_f * 0.1, 1.0);
    vec4 tex = texture(samp, tc + (normal.xy * 0.05 * blurAmt));
    
    // 6. Final Composition
    vec3 finalRGB = spiralColor * (diffuse + 0.4) + (specular * 0.5);
    
    // Mix the spiral sphere with the blurred background texture
    vec3 background = tex.rgb * 0.3; // Dimmed background
    vec3 result = mix(background, finalRGB, mask);
    
    // Add a glowing "Aura" ring at the edge
    float edgeGlow = smoothstep(radius + 0.05, radius - 0.05, d) * (1.0 - mask);
    result += neonGradient(time_f * 0.2) * edgeGlow * 0.5;

    color = vec4(result, 1.0);
}