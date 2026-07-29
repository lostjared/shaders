#version 330 core

out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

// Helper for seamless coordinate wrapping
vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

// Better random vector generation
vec2 hash2(float n) {
    return fract(sin(vec2(n, n + 1.0)) * vec4(43758.5453, 12345.6789, 22578.1459, 98765.4321).xy);
}

void main(void) {
    // 1. Smooth Path Generation
    float t = time_f * 0.5;
    float t_floor = floor(t);
    float t_fract = smoothstep(0.0, 1.0, fract(t)); // Smooth transition
    
    vec2 p0 = hash2(t_floor);
    vec2 p1 = hash2(t_floor + 1.0);
    vec2 center = mix(p0, p1, t_fract);

    // 2. Space Distortion
    vec2 uv = tc - center;
    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Dynamic Swirl that breathes
    float swirl = sin(time_f * 0.4) * 3.0;
    angle += swirl * exp(-r * 2.0); // Swirl is strongest at the center

    // Reconstruct UVs
    vec2 warpedUV = center + vec2(cos(angle), sin(angle)) * r;
    
    // Add a gentle "liquid" wave
    warpedUV += 0.015 * vec2(sin(tc.y * 10.0 + time_f), cos(tc.x * 10.0 + time_f));

    // 3. Chromatic Aberration (The "Neat" Factor)
    // We sample the texture 3 times at slightly different offsets
    float shift = 0.005 * r; 
    float r_chan = texture(samp, mirror(warpedUV + shift)).r;
    float g_chan = texture(samp, mirror(warpedUV)).g;
    float b_chan = texture(samp, mirror(warpedUV - shift)).b;

    // 4. Final Polish
    vec3 finalCol = vec3(r_chan, g_chan, b_chan);
    
    // Add a subtle vignette to focus on the center distortion
    float vignette = smoothstep(1.2, 0.2, r);
    finalCol *= vignette;

    color = vec4(finalCol, 1.0);
}