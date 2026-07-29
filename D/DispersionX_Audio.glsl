#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;
uniform float amp_peak; // peak absolute sample value in current audio buffer
uniform float amp_rms; // RMS energy of current audio buffer
uniform float amp_smooth; // exponentially smoothed amplitude for gradual transitions
uniform float amp_low; // bass energy (below ~300 Hz)
uniform float amp_mid; // mid-range energy (~300-3000 Hz)
uniform float amp_high; // treble energy (above ~3000 Hz)
uniform float iamp; // estimated dominant frequency in Hz via zero-crossing rate
const float PI = 3.14159265359;

mat3 rotX(float a){float s=sin(a),c=cos(a);return mat3(1,0,0, 0,c,-s, 0,s,c);}

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
        n = 1.0 - abs(n * 2.0 - 1.0);
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
    float ph = fract(t * 0.2);
    vec3 k1 = mix(pink, blue, smoothstep(0.00, 0.33, ph));
    vec3 k2 = mix(blue, green, smoothstep(0.33, 0.66, ph));
    vec3 k3 = mix(green, pink, smoothstep(0.66, 1.00, ph));
    float a = step(ph, 0.33);
    float b = step(0.33, ph) * step(ph, 0.66);
    float c = step(0.66, ph);
    return normalize(a * k1 + b * k2 + c * k3) * 1.2; 
}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    vec2 p2 = (tc - m) * ar;
    
    // AUDIO: Smooth energy accelerates the 3D tilt/rotation
    float ax = time_f * 0.5 + (amp_smooth * 5.0);
    mat3 R = rotX(ax);
    vec3 p3 = vec3(p2, 1.0);
    vec3 r = R * p3;

    float k = 0.6;
    float zf = 1.0 / (1.0 + r.z * k);
    vec2 projectedUV = r.xy * zf;

    // AUDIO: Mid-range frequencies increase the turbulence and speed of the electrical noise
    float elect = fbm(projectedUV * (4.0 + amp_mid * 8.0) - time_f * 1.5 - (amp_rms * 12.0));
    
    float dist = length(projectedUV);
    
    // AUDIO: Bass pushes the radial ripples outward dynamically
    float ripple = sin(dist * (20.0 + amp_low * 30.0) - time_f * 3.0 - (amp_low * 45.0));
    
    // AUDIO: Bass adds a direct "thump" to the perspective scale
    float scale = 1.0 + 0.2 * ripple * elect - (amp_low * 0.55); 
    projectedUV *= scale;

    vec2 tiledUV = 1.0 - abs(1.0 - 2.0 * (projectedUV + 0.5));
    tiledUV = tiledUV - floor(tiledUV);

    // AUDIO: Treble drives heavy chromatic aberration (color splitting)
    float dispersion = 0.02 * (0.5 + elect) + (amp_high * 0.30);
    vec2 dispOffset = normalize(projectedUV) * dispersion;

    vec2 uvR = tiledUV - dispOffset;
    vec2 uvG = tiledUV;
    vec2 uvB = tiledUV + dispOffset;

    float rChannel = texture(samp, clamp(uvR, 0.0, 1.0)).r;
    float gChannel = texture(samp, clamp(uvG, 0.0, 1.0)).g;
    float bChannel = texture(samp, clamp(uvB, 0.0, 1.0)).b;
    
    vec3 texColor = vec3(rChannel, gChannel, bChannel);

    // AUDIO: Smooth energy cycles the neon palette faster
    vec3 neon = neonPalette(time_f + dist + (amp_smooth * 12.0));
    
    // AUDIO: Mids lower the threshold for the glow, revealing more of the neon pattern
    float glowMask = smoothstep(0.4 - (amp_mid * 0.38), 0.9, elect);
    
    // AUDIO: Peak energy makes the neon overlay pulse much brighter
    vec3 finalColor = texColor + (neon * glowMask * (0.8 + amp_peak * 6.0));
    
    finalColor = finalColor / (1.0 + finalColor * 0.3);

    color = vec4(finalColor, 1.0);
}