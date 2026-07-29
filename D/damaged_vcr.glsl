#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

// Random functions for chaos
float rand(vec2 co) { return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453); }
float rand1(float x) { return fract(sin(x) * 43758.5453); } // Fixed name collision

vec3 brutalColorDistortion(vec3 col, vec2 uv, float t) {
    // Channel separation madness
    col.r = texture(samp, uv + vec2(sin(t*0.7)*0.03, cos(t*0.3)*0.02)).r;
    col.g = texture(samp, uv + vec2(sin(t*0.5)*0.02, cos(t*0.4)*0.03)).g;
    col.b = texture(samp, uv + vec2(sin(t*0.9)*0.04, cos(t*0.6)*0.01)).b;
    
    // Random color channel swaps
    if (mod(t, 3.0) > 2.0) col = col.bgr;
    if (mod(t*0.7, 2.0) > 1.3) col = col.grb;
    
    return col;
}

void main(void) {
    vec2 uv = tc;
    float t = time_f * 3.0;
    
    // Extreme geometric distortion
    uv.x += sin(uv.y * 50.0 + t * 10.0) * 0.1 * rand1(t);
    uv.y += cos(uv.x * 40.0 + t * 8.0) * 0.08 * rand1(t+0.3);
    
    // Tape stretch apocalypse
    uv.x += sin(t * 5.0 + uv.y * 50.0) * 0.05;
    uv.y += cos(t * 3.0 + uv.x * 60.0) * 0.03;
    
    // Violent vertical/horizontal jitter
    uv += vec2(rand1(t) - 0.5, rand1(t+0.5) - 0.5) * 0.1;
    
    // CRT curvature distortion
    vec2 crtUV = uv * 2.0 - 1.0;
    crtUV *= 1.0 + pow(length(crtUV), 3.0) * 0.5;
    uv = crtUV * 0.5 + 0.5;
    
    // Severe tracking errors (split screen)
    float split = step(0.5 + sin(t)*0.2, uv.x);
    uv.y += split * (sin(t*2.0) * 0.1 * rand1(t));
    
    // Burning VCR head effect
    float scanLine = fract(t * 0.3);
    if(abs(uv.y - scanLine) < 0.02) {
        uv.x += (rand1(uv.y + t) - 0.5) * 0.3;
        uv.y += sin(uv.x * 100.0) * 0.1;
    }
    
    // Total chromatic breakdown (FIXED texture sampling)
    vec3 col = brutalColorDistortion(texture(samp, uv).rgb, uv, t);
    
    // Tape damage zones (FIXED missing parenthesis)
    float damageZone = step(0.9, rand(vec2(floor(uv.y * 20.0 + t * 0.5))));
    col = mix(col, vec3(0.0), damageZone * 0.7);
    
    // Static electricity bursts
    float staticFlash = step(0.997, rand1(t * 0.1));
    col += vec3(staticFlash * 2.0);
    
    // Magnetic interference waves
    col *= 0.7 + 0.3 * sin(uv.x * 300.0 + t * 10.0);
    
    // Extreme noise pollution
    vec3 noise = vec3(rand(uv * t), rand(uv * t + 0.3), rand(uv * t + 0.7)) * 0.8;
    col += noise * smoothstep(0.3, 0.7, rand1(t * 0.3));
    
    // Tape crease distortion
    float crease = sin(uv.y * 30.0 + t * 5.0) * 0.1;
    col *= 1.0 - smoothstep(0.3, 0.7, abs(crease));
    
    // Overload red channel
    col.r += sin(t * 5.0) * 0.3 + rand1(uv.x) * 0.2;
    
    // VCR menu burn-through
    float osd = step(0.98, rand1(uv.x * 10.0 + t * 0.1));
    col = mix(col, vec3(0.0, 1.0, 0.0), osd * 0.3);
    
    // Final output with scanline darkness
    color = vec4(col, 1.0);
    color *= 0.8 + 0.2 * sin(uv.y * 800.0 + t * 10.0);
    
    // Add random full-screen flicker
    color *= 0.7 + 0.3 * rand1(t * 0.1);
    
    // Edge collapse
    color *= smoothstep(0.0, 0.2, uv.y) * smoothstep(1.0, 0.8, uv.y);
    color *= smoothstep(0.0, 0.1, uv.x) * smoothstep(1.0, 0.9, uv.x);
}