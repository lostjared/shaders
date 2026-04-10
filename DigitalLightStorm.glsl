#version 330 core

out vec4 color;
in vec2 tc;

// STRICT UNIFORM LIST
uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;
float seed = 1.0;

const float PI = 3.1415926535897932384626433832795;

// --- UTILS: XOR BLENDING ---
vec4 xor_RGB(vec4 icolor, vec4 source){
    ivec3 int_color;
    ivec4 isource = ivec4(source * 255.0);
    for(int i=0;i<3;++i){
        int_color[i] = int(255.0*icolor[i]);
        int_color[i] = int_color[i] ^ isource[i];
        if(int_color[i]>255) int_color[i] = int_color[i] % 255;
        icolor[i] = float(int_color[i]) / 255.0;
    }
    icolor.a = 1.0;
    return icolor;
}

// --- UTILS: MATH & GEOMETRY ---
float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect) {
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

vec2 reflectUV(vec2 uv, float segments, vec2 c, float aspect) {
    vec2 p = uv - c;
    p.x *= aspect;
    float ang = atan(p.y, p.x);
    float rad = length(p);
    float stepA = 6.28318530718 / segments;
    ang = mod(ang, stepA);
    ang = abs(ang - stepA * 0.5);
    vec2 r = vec2(cos(ang), sin(ang)) * rad;
    r.x /= aspect;
    return r + c;
}

// Combined electrical fold with audio-reactive zoom
vec2 electricalFold(vec2 uv, float zoom, float t, vec2 c, float aspect) {
    vec2 p = uv;
    // 4 iterations to keep it sharp and efficient
    for (int i = 0; i < 4; i++) {
        // Use seed to vary the fractal folding structure slightly
        float iSeed = seed * 0.1 * float(i);
        p = abs((p - c) * (zoom + 0.1 * sin(t * 1.5 + float(i) + iSeed))) - 0.5 + c;
        p = rotateUV(p, t * 0.2 + float(i) * 0.1, c, aspect);
    }
    return p;
}

// --- UTILS: COLOR ---
vec3 neonPalette(float t) {
    vec3 pink = vec3(1.0, 0.15, 0.75);
    vec3 electric = vec3(0.10, 0.90, 1.0); // Cyan
    vec3 purple = vec3(0.60, 0.10, 1.0);
    
    float ph = fract(t * 0.4); 
    vec3 k1 = mix(pink, electric, smoothstep(0.00, 0.33, ph));
    vec3 k2 = mix(electric, purple, smoothstep(0.33, 0.66, ph));
    vec3 k3 = mix(purple, pink, smoothstep(0.66, 1.00, ph));
    
    return normalize(k1 + k2 + k3) * 1.3;
}

vec3 limitHighlights(vec3 c){
    float m = max(c.r, max(c.g, c.b));
    if(m > 0.9) c *= 0.9 / m;
    return c;
}

void main(void) {
    seed = pingPong(time_f * PI, 15.0);
    // --- STEP 1: SETUP ---
    float a = clamp(amp, 0.0, 1.0);
    float ua = clamp(uamp, 0.0, 1.0);
    
    // Create an aggregate intensity value
    float intensity = clamp(amp * 0.6 + uamp * 1.2, 0.0, 3.0); 
    float tFast = time_f + intensity; 

    float aspect = iResolution.x / iResolution.y;
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    // --- STEP 2: RGB CHANNEL SPLIT (Glitch) ---
    // Uses amp/uamp to shake the background planes
    vec2 uv = tc;
    float distAmt = 0.02 * intensity; 
    
    // Offset sin waves by seed so the shake pattern isn't identical every time
    float rR = sin(uv.y * 10.0 + time_f * 5.0 + seed) * distAmt;
    float rG = sin(uv.x * 12.0 + time_f * 4.0 + seed * 1.3) * distAmt;
    float rB = sin(uv.y * 8.0  + time_f * 6.0 + seed * 0.7) * distAmt;

    vec2 tcR = uv + vec2(rR, 0.0);
    vec2 tcG = uv + vec2(0.0, rG);
    vec2 tcB = uv + vec2(rB, rB * 0.5);

    vec4 texR = texture(samp, tcR);
    vec4 texG = texture(samp, tcG);
    vec4 texB = texture(samp, tcB);
    
    vec4 baseTex = vec4(texR.r, texG.g, texB.b, 1.0);

    // --- STEP 3: KALEIDOSCOPIC LIGHTNING ---
    vec2 kUV = tc;
    
    // Number of mirror segments increases with loud audio
    float segs = 4.0 + floor(intensity * 2.0) * 2.0; 
    kUV = reflectUV(kUV, segs, m, aspect);
    
    // Zoom pulses with the bass
    float zoom = 1.1 + 0.3 * sin(time_f) + 0.4 * intensity;
    
    // Generate Lightning Geometry
    vec2 electricUV = electricalFold(kUV, zoom, tFast * 0.3, m, aspect);
    
    // Calculate distance field for the bolt
    float dist = length(electricUV - m);
    float bolt = 0.015 / (dist + 0.001); 
    bolt = pow(bolt, 1.2); 
    
    // Pulse the lightning using pingPong
    float pulse = pingPong(tFast * 4.0, 1.0);
    bolt *= (0.5 + 0.5 * pulse);
    bolt *= (0.8 + 0.5 * intensity); 

    // --- STEP 4: COLOR & BLENDING ---
    vec3 boltColor = neonPalette(time_f + dist * 2.0);
    
    // XOR Interference: Masked to the bolt area
    vec4 interference = vec4(boltColor, 1.0) * bolt;
    vec4 xorLayer = xor_RGB(baseTex, interference * 2.5);
    
    // Mix strategy
    vec3 finalCol = baseTex.rgb;
    
    // Mix in the glitch where lightning is strong
    finalCol = mix(finalCol, xorLayer.rgb, clamp(bolt * 0.6, 0.0, 0.8));
    
    // Add bloom
    finalCol += boltColor * bolt * 0.8;
    
    // Global flash on high intensity beats
    if (uamp > 0.8) {
        finalCol += vec3(0.1, 0.1, 0.2) * uamp;
    }

    // --- STEP 5: FINAL OUTPUT ---
    finalCol = limitHighlights(finalCol);
    
    color = vec4(finalCol, 1.0);
}