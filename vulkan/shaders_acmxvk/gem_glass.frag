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
#define iResolution ext.u0.zw
#define time_f ext.u2.y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;




void main(void) {
    // 1. Setup Base Coordinates
    vec2 uv = tc;
    float pulse = sin(time_f * 0.5) * 0.1 + 0.5;
    
    // 2. Create the "Glass Warp" Offset
    // We sample the texture at a few points to find the "slope" (gradient)
    float delta = 0.01;
    float h  = dot(texture(samp, uv).rgb, vec3(0.33)); 
    float h1 = dot(texture(samp, uv + vec2(delta, 0.0)).rgb, vec3(0.33));
    float h2 = dot(texture(samp, uv + vec2(0.0, delta)).rgb, vec3(0.33));
    
    // Calculate the Normal (the direction the "glass" surface faces)
    vec2 normal = vec2(h1 - h, h2 - h);
    
    // 3. Add the Spiral + Zoom from before, but influenced by the Glass Normal
    vec2 centeredUV = uv - 0.5;
    float dist = length(centeredUV);
    float angle = atan(centeredUV.y, centeredUV.x);
    
    // The spiral is now "distorted" by the surface normals
    float spiral = angle + (dist * 8.0) + (time_f * 0.2) + (normal.x * 2.0 * amp);
    float zoom = dist * (0.8 + uamp * 0.2);
    
    vec2 glassUV;
    glassUV.x = cos(spiral) * zoom + 0.5 + (normal.x * 0.05);
    glassUV.y = sin(spiral) * zoom + 0.5 + (normal.y * 0.05);

    // 4. Sample with Chromatic Aberration
    // Refraction in glass usually splits light into its component colors
    vec3 finalCol;
    float refractor = 0.02 * (amp + uamp + 0.1);
    finalCol.r = texture(samp, glassUV + (normal * refractor)).r;
    finalCol.g = texture(samp, glassUV).g;
    finalCol.b = texture(samp, glassUV - (normal * refractor)).b;

    // 5. Specular Highlights (The "Glassy" Shine)
    // This adds white glints where the "slope" is steepest
    float specular = pow(max(0.0, 1.0 - length(normal * 20.0)), 10.0);
    finalCol += vec3(1.0) * specular * 0.4;

    // 6. Edge darkening (Vignette)
    finalCol *= smoothstep(1.2, 0.3, dist);

    color = vec4(finalCol, 1.0);
}