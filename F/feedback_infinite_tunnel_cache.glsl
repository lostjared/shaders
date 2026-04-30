#version 330 core
// Infinite Kaleidoscope Base + Deep Recursive History Tunnel

in vec2 tc;
out vec4 color;

// --- Base Inputs ---
uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

// --- Ring Buffer Inputs ---
uniform sampler2D samp1;
uniform sampler2D samp2;
uniform sampler2D samp3;
uniform sampler2D samp4;
uniform sampler2D samp5;
uniform sampler2D samp6;
uniform sampler2D samp7;
uniform sampler2D samp8;

vec3 neonRing(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

vec4 sampleCache(int idx, vec2 uv) {
    if (idx == 0) return texture(samp1, uv);
    if (idx == 1) return texture(samp2, uv);
    if (idx == 2) return texture(samp3, uv);
    if (idx == 3) return texture(samp4, uv);
    if (idx == 4) return texture(samp5, uv);
    if (idx == 5) return texture(samp6, uv);
    if (idx == 6) return texture(samp7, uv);
    return texture(samp8, uv);
}

void main() {
    // ==========================================
    // 1. AUDIO SENSING
    // ==========================================
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= aspect;

    // ==========================================
    // 2. KALEIDOSCOPE FOLDING (Base Video Layer)
    // ==========================================
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);

    // Fold the space into 6 symmetrical segments
    float segments = 6.0;
    angle = mod(angle, 6.28318 / segments);
    angle = abs(angle - 3.14159 / segments);

    // Reconstruct the UV coordinates from the folded polar math
    vec2 kalUV = vec2(cos(angle), sin(angle)) * radius;
    
    // Map back to 0.0 - 1.0 texture space
    vec2 baseUV = kalUV * 0.5 + 0.5;
    baseUV.x /= aspect; // Correct aspect stretch

    // Sample the base video with chromatic split
    float chroma = (mid + treble) * 0.02;
    vec3 baseCol;
    baseCol.r = texture(samp, baseUV + vec2(chroma, 0.0)).r;
    baseCol.g = texture(samp, baseUV).g;
    baseCol.b = texture(samp, baseUV - vec2(chroma, 0.0)).b;

    // Audio flash / inversion
    baseCol *= 0.85 + amp_smooth * 0.35;
    baseCol *= 1.0 + bass * 0.3;
    baseCol = mix(baseCol, vec3(1.0) - baseCol, smoothstep(0.93, 1.0, amp_peak));

    // ==========================================
    // 3. RING BUFFER FEEDBACK RECURSION
    // ==========================================
    // FIX 1: Zoom multiplier > 1.0 forces coordinates outward, making the rendered
    // history frames smaller on screen. This creates the deep receding tunnel.
    float fbZoomPerLayer = 1.05 + (bass * 0.02); 
    float fbRotPerLayer = 0.04 * sin(iTime * 0.3);

    vec2 feedbackCenter = vec2(
        0.5 + 0.015 * sin(iTime * 0.4),
        0.5 + 0.015 * cos(iTime * 0.35)
    );

    vec3 accum = baseCol;
    float accWeight = 1.0;

    for (int i = 0; i < 8; i++) {
        float gen = float(i + 1);

        // Compound the transform recursively
        float fbZoomGen = pow(fbZoomPerLayer, gen);
        float rot = fbRotPerLayer * gen;
        float cs = cos(rot), sn = sin(rot);

        vec2 centered = tc - feedbackCenter;
        
        // Apply receding zoom
        centered *= fbZoomGen; 
        
        // Apply rotation
        centered = vec2(centered.x * cs - centered.y * sn,
                        centered.x * sn + centered.y * cs);
                        
        vec2 fbUV = centered + feedbackCenter;

        // FIX 2: We removed the chaotic fractal vector 'p' from this step.
        // The coordinates are mathematically pure, so the tunnel walls won't tear into static.
        vec4 cached = sampleCache(i, fbUV);

        // Shift history colors over depth (Creates the purple/mauve trail)
        float shift = gen * 0.035;
        cached.r *= 1.0 + shift;
        cached.g *= 1.0 - shift * 0.5;
        cached.b *= 1.0 + shift * 0.8;

        // Exponential decay so deeper tunnel segments fade out smoothly
        float w = pow(0.75, gen);
        accum += cached.rgb * w;
        accWeight += w;
    }

    accum /= accWeight;

    // Contrast boost to keep the deep center punchy
    accum = (accum - 0.5) * 1.2 + 0.5;
    accum = clamp(accum, 0.0, 1.0);

    color = vec4(accum, 1.0);
}