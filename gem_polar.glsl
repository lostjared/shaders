#version 330 core
in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;

void main(void) {
    // 1. Center the coordinates (-1.0 to 1.0) and fix aspect ratio
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= iResolution.x / iResolution.y;

    // 2. Simple Circle Math (No Triangles)
    // 'dist' is the radius from the center
    // 'angle' is the rotation around the center
    float dist = length(uv);
    float angle = atan(uv.x, uv.y) / 3.14159;

    // 3. Create Seamless Warp Coordinates
    // Using log(dist) makes the "tunnel" perspective smooth and infinite
    // Adding time_f to 'dist' makes it zoom; adding it to 'angle' makes it spin
    vec2 warpedTC;
    warpedTC.x = angle + (time_f * 0.05); 
    warpedTC.y = (1.0 / (dist + 0.01)) + (time_f * 0.5);

    // 4. The Mirror Trick (Removes all rough edges/seams)
    // 'fract' keeps it in 0-1 range, then the 'abs' math mirrors it
    // so the edges of the texture always meet their own reflection.
    vec2 finalTC = abs(fract(warpedTC * 0.5) * 2.0 - 1.0);
    
    // Sample the texture
    vec4 texColor = texture(samp, finalTC);

    // 5. Psychedelic Color Grade (Matching your reference)
    // Cycles colors based on distance and time
    vec3 rainbow = 0.5 + 0.5 * cos(6.28318 * (dist - time_f * 0.4 + vec3(0.0, 0.33, 0.67)));
    
    // Vignette: Darkens the very center and the very edges for a cleaner look
    float vignette = smoothstep(0.0, 0.1, dist) * smoothstep(1.5, 0.5, dist);
    
    color = texColor * vec4(rainbow, 1.0) * vignette;
}