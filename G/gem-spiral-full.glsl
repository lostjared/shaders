#version 330 core

out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float alpha;

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    // 1. Correct Aspect Ratio & Centering
    vec2 uv = (tc * 2.0 - 1.0);
    float aspect = iResolution.x / iResolution.y;
    uv.x *= aspect;
    
    // 2. Full-Screen Spherical/Fisheye Logic
    float d = length(uv);
    
    // Instead of a fixed sphereRadius, we use a 'lens strength'
    // This creates a bulge that covers the whole screen.
    float lensStrength = 1.5; 
    float z = sqrt(lensStrength * lensStrength + d * d); // Hyperbolic-style depth
    
    // Create normals for shading (lighting) across the whole screen
    vec3 normal = normalize(vec3(uv, 1.0 / lensStrength));
    
    // Distort UVs for the spiral - no more "if" discard block
    float fisheyeRadius = atan(d, 1.0); 
    vec2 distortedUV = normalize(uv + 1e-6) * fisheyeRadius;

    // 3. Spiral Logic (Ping-Ponging the direction and tightness)
    float t = time_f * 0.8;
    float pTime = pingPong(time_f * 0.5, 2.0); // Used to oscillate spiral intensity
    
    float r_dist = length(distortedUV);
    float angle = atan(distortedUV.y, distortedUV.x);
    
    // Enhanced Spiral: we use pTime to make it 'unwind' and 'rewind'
    float spiral = angle + (log(r_dist + 0.1) * (2.0 + pTime)) - t * 1.5;
    
    // Color generation (Neon Spectrum)
    float r = sin(spiral * 3.0 + t);
    float g = sin(spiral * 3.0 + t + 2.094);
    float b = sin(spiral * 3.0 + t + 4.188);
    
    vec3 spiralCol = vec3(r, g, b) * 0.5 + 0.5;
    
    // 4. Shading & Lighting (Applied globally)
    vec3 lightDir = normalize(vec3(sin(time_f), cos(time_f), 1.0)); // Moving light
    float diff = max(dot(normal, lightDir), 0.0);
    float spec = pow(max(dot(reflect(-lightDir, normal), vec3(0,0,1)), 0.0), 16.0);
    
    // 5. Final Mix
    vec3 texColor = texture(samp, tc).rgb;
    
    // We mix the spiral with the texture based on the distance from center
    // to keep the center clear or create an 'aura' feel
    float mixFactor = smoothstep(0.0, 1.5, d); 
    
    vec3 finalCol = mix(texColor, spiralCol * (diff + 0.5) + spec, 0.7);
    
    // Subtle vignette to focus the screen
    finalCol *= smoothstep(2.0, 0.5, d);
    
    color = vec4(finalCol, alpha);
}