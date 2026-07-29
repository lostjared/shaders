#version 330 core

out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float alpha;

// Neon Palette Generator from your second shader
vec3 neonGradient(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

void main(void) {
    vec3 texCol = texture(samp, tc).rgb;
    
    // Threshold check for "black" pixels
    if(texCol.r < 0.3 && texCol.g < 0.3 && texCol.b < 0.3) {
        // 1. Setup Coordinates
        vec2 uv = (tc * 2.0 - 1.0);
        float aspect = iResolution.x / iResolution.y;
        uv.x *= aspect;
        
        float d = length(uv);
        float lensStrength = 1.5; 
        
        // 2. Lighting / Normal math
        vec3 normal = normalize(vec3(uv, 1.0 / lensStrength));
        float fisheyeRadius = atan(d, 1.0); 
        vec2 distortedUV = normalize(uv + 1e-6) * fisheyeRadius;

        float t = time_f * 0.8;
        float r_dist = length(distortedUV);
        float angle = atan(distortedUV.y, distortedUV.x);
        
        // 3. Spiral Calculation
        // The formula for the spiral angle is:
        // $spiral = \theta + 3.0 \cdot \ln(r + 0.1) - 1.5t$
        float spiral = angle + (log(r_dist + 0.1) * 3.0) - t * 1.5;
        
        float r = sin(spiral * 3.0 + t);
        float g = sin(spiral * 3.0 + t + 2.094);
        float b = sin(spiral * 3.0 + t + 4.188);
        
        vec3 spiralCol = vec3(r, g, b) * 0.5 + 0.5;
        
        // 4. Shading
        vec3 lightDir = normalize(vec3(sin(time_f), cos(time_f), 1.0));
        float diff = max(dot(normal, lightDir), 0.0);
        float spec = pow(max(dot(reflect(-lightDir, normal), vec3(0,0,1)), 0.0), 16.0);
        
        vec3 finalSpiral = spiralCol * (diff + 0.5) + spec;
        
        // Apply the neon gradient and vignette
        finalSpiral *= neonGradient(time_f);
        finalSpiral *= smoothstep(2.0, 0.5, d);
        
        color = vec4(finalSpiral, alpha);
    }
    else {
        // Leave the other colors as they are
        color = vec4(texCol, 1.0);
    }
}