#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;

// --- CONSTANTS & UTILS ---
const float PI = 3.14159265359;

mat3 rotX(float a){float s=sin(a),c=cos(a);return mat3(1,0,0, 0,c,-s, 0,s,c);}
mat3 rotY(float a){float s=sin(a),c=cos(a);return mat3(c,0,s, 0,1,0, -s,0,c);}
mat3 rotZ(float a){float s=sin(a),c=cos(a);return mat3(c,-s,0, s,c,0, 0,0,1);}

// --- NOISE & PALETTE (From Shader 2) ---
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        float n = noise(p);
        n = 1.0 - abs(n * 2.0 - 1.0); // Turbulence
        v += a * n;
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

vec3 neonPalette(float t) {
    vec3 pink = vec3(1.0, 0.15, 0.75);
    vec3 blue = vec3(0.10, 0.55, 1.0);
    vec3 green = vec3(0.10, 1.00, 0.45);
    float ph = fract(t * 0.2); // Slowed down slightly
    vec3 k1 = mix(pink, blue, smoothstep(0.00, 0.33, ph));
    vec3 k2 = mix(blue, green, smoothstep(0.33, 0.66, ph));
    vec3 k3 = mix(green, pink, smoothstep(0.66, 1.00, ph));
    float a = step(ph, 0.33);
    float b = step(0.33, ph) * step(ph, 0.66);
    float c = step(0.66, ph);
    return normalize(a * k1 + b * k2 + c * k3) * 1.2; 
}

// --- MAIN LOGIC ---
void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    // 1. 3D PROJECTION (From Shader 1)
    // We start by creating a 3D coordinate system that tumbles
    vec2 p2 = (tc - m) * ar;
    
    // Rotation speeds derived from Shader 1
    float ax = 0.25 * sin(time_f * 0.5);
    float ay = 0.25 * cos(time_f * 0.4);
    float az = time_f * 0.2;

    vec3 p3 = vec3(p2, 1.0);
    mat3 R = rotZ(az) * rotY(ay) * rotX(ax);
    vec3 r = R * p3;

    // Perspective projection
    float k = 0.6;
    float zf = 1.0 / (1.0 + r.z * k);
    vec2 projectedUV = r.xy * zf;

    // 2. ELECTRIC NOISE & RIPPLE (Combining Shader 2 & 3)
    // Calculate noise based on the projected 3D coordinates + time
    float elect = fbm(projectedUV * 4.0 - time_f * 1.5);
    
    // Create the Ripple effect (Shader 3) but modulate it with the Noise (Shader 2)
    float dist = length(projectedUV);
    float ripple = sin(dist * 20.0 - time_f * 3.0);
    
    // Scale the projection based on the ripple
    float scale = 1.0 + 0.15 * ripple * elect; 
    projectedUV *= scale;

    // 3. MIRROR TILING (From Shader 4)
    // Instead of simple clamping, we use the absolute mirror logic
    // This creates the kaleidoscope effect on the 3D surface
    vec2 tiledUV = 1.0 - abs(1.0 - 2.0 * (projectedUV + 0.5));
    tiledUV = tiledUV - floor(tiledUV);

    // 4. CHROMATIC ABERRATION (From Shader 3)
    // We separate the channels. The offset is determined by the electric noise intensity.
    float dispersion = 0.02 * (0.5 + elect); // Dispersion reacts to noise
    vec2 dispOffset = normalize(projectedUV) * dispersion;

    // Calculate RGB coords
    vec2 uvR = tiledUV - dispOffset;
    vec2 uvG = tiledUV;
    vec2 uvB = tiledUV + dispOffset;

    // 5. COLOR COMPOSITING
    // Sample texture with aberration
    float rChannel = texture(samp, clamp(uvR, 0.0, 1.0)).r;
    float gChannel = texture(samp, clamp(uvG, 0.0, 1.0)).g;
    float bChannel = texture(samp, clamp(uvB, 0.0, 1.0)).b;
    
    vec3 texColor = vec3(rChannel, gChannel, bChannel);

    // Add the Neon Palette Glow (From Shader 2)
    // We use the 'elect' value to mask where the neon appears (in the "cracks" of the noise)
    vec3 neon = neonPalette(time_f + dist);
    float glowMask = smoothstep(0.4, 0.9, elect);
    
    // Additive blend: Texture + (Neon * GlowIntensity)
    vec3 finalColor = texColor + (neon * glowMask * 0.8);
    
    // Soft tone mapping to prevent total blowout
    finalColor = finalColor / (1.0 + finalColor * 0.3);

    color = vec4(finalColor, 1.0);
}