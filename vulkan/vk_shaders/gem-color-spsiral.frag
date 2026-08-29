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
#define alpha ext.u0.x
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;




float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    // 1. Correct Aspect Ratio & Centering
    vec2 uv = (tc * 2.0 - 1.0);
    float aspect = iResolution.x / iResolution.y;
    uv.x *= aspect;
    
    // 2. Spherical Projection Logic
    float d = length(uv);
    float sphereRadius = 0.8; // Controls the size of the ball
    
    // Discard pixels outside the sphere to keep it a perfect circle
    if (d > sphereRadius) {
        // Optional: render background texture dimmed
        color = vec4(texture(samp, tc).rgb * 0.2, alpha);
        return;
    }
    
    // Calculate "Z" depth of the sphere
    float z = sqrt(sphereRadius * sphereRadius - d * d);
    
    // Create spherical normals (for lighting and distortion)
    vec3 normal = normalize(vec3(uv, z));
    
    // Distort UVs based on sphere curvature (the "pinch")
    // atan(d, z) maps the flat plane onto a hemisphere
    float fisheyeRadius = atan(d, z); 
    vec2 sphereUV = normalize(uv) * fisheyeRadius;

    // 3. Spiral Logic (Applied to distorted sphereUV)
    float t = time_f * 0.8;
    float r_dist = length(sphereUV);
    float angle = atan(sphereUV.y, sphereUV.x);
    
    // Spiral formula: angle + log(radius)
    float spiral = angle + (log(r_dist + 0.1) * 3.0) - t * 2.0;
    
    // Color generation
    float r = sin(spiral * 2.0 + t);
    float g = sin(spiral * 2.0 + t + 2.094); // 120 deg shift
    float b = sin(spiral * 2.0 + t + 4.188); // 240 deg shift
    
    vec3 spiralCol = vec3(r, g, b) * 0.5 + 0.5;
    
    // 4. Shading & Lighting
    // Simple directional light from top-right
    vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
    float diff = max(dot(normal, lightDir), 0.0);
    
    // Specular highlight (the shiny "glint")
    float spec = pow(max(dot(reflect(-lightDir, normal), vec3(0,0,1)), 0.0), 32.0);
    
    // 5. Final Mix
    vec3 texColor = texture(samp, tc).rgb;
    
    // Apply diffuse lighting and specular to the spiral
    vec3 finalCol = spiralCol * (diff + 0.3) + spec;
    
    // Mix with original texture and apply sphere edge darkening
    finalCol = mix(finalCol, texColor, 0.2);
    finalCol *= smoothstep(sphereRadius, sphereRadius - 0.02, d); // Anti-aliased edge
    
    color = vec4(finalCol, alpha);
}