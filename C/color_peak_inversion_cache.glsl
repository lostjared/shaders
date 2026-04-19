#version 330 core
// ant_light_color_acid_ripple_spiral_ringbuffer
// Audio-reactive spirals, rippling interference, and an 8-frame recursive feedback tunnel

in vec2 tc;
out vec4 color;

// Live feed and cache layers
uniform sampler2D samp;
uniform sampler2D samp1;
uniform sampler2D samp2;
uniform sampler2D samp3;
uniform sampler2D samp4;
uniform sampler2D samp5;
uniform sampler2D samp6;
uniform sampler2D samp7;
uniform sampler2D samp8;

// Uniforms
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

// Procedural Palette
vec3 acid(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 0.5);
    vec3 d = vec3(0.3, 0.2, 0.2);
    return a + b * cos(TAU * (c * t + d));
}

// Helper to fetch history frames
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
    // 1. Extract Audio Data
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // 2. Base Interference & Glitch Distortion (Current Frame)
    vec2 src1 = vec2(sin(iTime * 0.3) * 0.2, cos(iTime * 0.4) * 0.15);
    vec2 src2 = vec2(-sin(iTime * 0.5) * 0.15, sin(iTime * 0.3) * 0.2);
    vec2 src3 = vec2(cos(iTime * 0.2) * 0.1, -cos(iTime * 0.6) * 0.1);

    float r1 = length(uv - src1);
    float r2 = length(uv - src2);
    float r3 = length(uv - src3);

    float wave1 = sin(r1 * (20.0 + bass * 15.0) - iTime * 5.0);
    float wave2 = sin(r2 * (18.0 + mid * 12.0) - iTime * 4.0);
    float wave3 = sin(r3 * (22.0 + treble * 10.0) - iTime * 6.0);

    float combined = (wave1 + wave2 + wave3) / 3.0;

    // UV distortion for the live feed
    vec2 distort = vec2(
        combined * 0.03 * (1.0 + bass),
        (wave1 - wave2) * 0.02 * (1.0 + mid)
    );
    vec2 sampUV = tc + distort;

    // Chromatic aberration on the live feed
    float chroma = abs(combined) * 0.04 + treble * 0.02;
    vec3 current_col;
    current_col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    current_col.g = texture(samp, sampUV).g;
    current_col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Add acid interference and crests
    float interference = combined * 0.5 + 0.5;
    current_col *= acid(interference + iTime * 0.1 + bass) * 1.5;
    
    float crest = pow(max(combined, 0.0), 6.0);
    current_col += acid(r1 + iTime * 0.2) * crest * (1.0 + air * 2.0);

    // 3. Add Polar Spirals
    float r_center = length(uv);
    float theta = atan(uv.y, uv.x);
    
    float spiralArms = 3.0 + floor(treble * 4.0);
    float spiralTwist = 15.0 - bass * 8.0;
    float spiralSpeed = iTime * (4.0 + amp_smooth * 8.0);
    
    float spiralPhase = theta * spiralArms - r_center * spiralTwist - spiralSpeed;
    float spiralBeams = pow(max(sin(spiralPhase), 0.0), 5.0);
    float spiralFalloff = exp(-r_center * (2.0 - mid)); 
    vec3 spiralColor = acid(r_center * 0.8 - iTime * 0.5 + mid * 0.5);
    
    current_col += spiralColor * spiralBeams * (0.6 + bass * 2.0) * spiralFalloff;
    current_col *= 0.85 + amp_smooth * 0.35;

    // 4. Ring Buffer Recursion
    vec3 accum = current_col;
    float accWeight = 1.0;

    // Audio-reactive feedback parameters
    // Bass punches the zoom outward; heavy tracks will breathe visually
    float zoomPerLayer = 0.96 + 0.02 * sin(iTime * 0.5) - (bass * 0.03); 
    // Treble/Hi-hats add a nervous jitter to the rotation
    float rotPerLayer = 0.03 * sin(iTime * 0.3) + (treble * 0.015);

    // Tie the feedback center into the core glitch distortion
    vec2 feedbackCenter = vec2(0.5) + distort * 2.0;

    for (int i = 0; i < 8; i++) {
        float gen = float(i + 1);

        float zoom = pow(zoomPerLayer, gen);
        float rot = rotPerLayer * gen;
        float cs = cos(rot), sn = sin(rot);

        // Center, apply compound scale/rotate, uncenter
        vec2 centered = tc - feedbackCenter;
        centered *= zoom;
        centered = vec2(centered.x * cs - centered.y * sn,
                        centered.x * sn + centered.y * cs);
        vec2 fbUV = centered + feedbackCenter;

        vec4 cached = sampleCache(i, fbUV);

        // Acidic Hue drift per layer
        float shift = gen * 0.02;
        cached.r *= 1.0 + shift + (mid * 0.01);
        cached.g *= 1.0 - shift * 0.5;
        cached.b *= 1.0 + shift * 0.3 + (air * 0.01);

        float w = pow(0.75, gen); // Decay rate
        accum += cached.rgb * w;
        accWeight += w;
    }

    accum /= accWeight;

    // 5. Final Processing
    accum = (accum - 0.5) * 1.15 + 0.5; // Contrast recovery
    accum = clamp(accum, 0.0, 1.0);
    
    // Hard inversion glitch on absolute audio peaks
    accum = mix(accum, vec3(1.0) - accum, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(accum, 1.0);
}