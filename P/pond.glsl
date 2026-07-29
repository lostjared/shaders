#version 330 core
// ant_cache_spectrum8_chromatic_pulse_water_splash_mouse_10x_darker
// Extreme rippling displacement with aggressive chromatic tearing and noise, brightness tamed

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler2DArray history;
uniform int history_head;
#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif

uniform sampler1D spectrum0;
uniform sampler1DArray spectrum_history;
uniform int spectrum_history_head;
uniform int spectrum_history_size;
#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif

uniform float iTime;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp_peak;
uniform float amp_smooth;

const float TAU = 6.28318530718;
const float PI  = 3.14159265359;

float specHist(int i, float f) {
    if (i == 0) return texture(spectrum0, f).r;
    if (i == 1) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(1)))).r;
    if (i == 2) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(2)))).r;
    if (i == 3) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(3)))).r;
    if (i == 4) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(4)))).r;
    if (i == 5) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(5)))).r;
    if (i == 6) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(6)))).r;
    return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(7)))).r;
}

vec4 cacheHist(int i, vec2 uv) {
    if (i == 0) return texture(samp,  uv);
    if (i == 1) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));
    if (i == 2) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));
    if (i == 3) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));
    if (i == 4) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));
    if (i == 5) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));
    if (i == 6) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));
    if (i == 7) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float energy() {
    float e = 0.0;
    for (int i = 0; i < 8; i++) {
        e += specHist(i, 0.05) + specHist(i, 0.25) + specHist(i, 0.6);
    }
    return e / 24.0;
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    
    vec2 mPos = iMouse.xy;
    if (length(mPos) < 1.0) {
        mPos = iResolution.xy * 0.5;
    }
    
    vec2 mouseNorm = mPos / iResolution.xy;
    vec2 mouseUV = (mouseNorm - 0.5) * vec2(aspect, 1.0);
    
    vec2 delta = uv - mouseUV;
    float d = length(delta);
    vec2 dir = delta / (d + 0.0001); 
    
    float bass   = texture(spectrum0, 0.03).r;
    float mid    = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float e      = energy();

    // Hyper-reactive wave frequencies
    float waveFreq = 60.0 + mid * 40.0;
    float waveSpeed = 15.0 + treble * 10.0;
    float phase = d * waveFreq - iTime * waveSpeed;
    
    float decay = exp(-d * 1.2); 

    float isClicked = iMouse.z > 0.0 ? 1.0 : 0.0;

    vec3 acc = vec3(0.0);
    
    for (int i = 0; i < 8; i++) {
        float fi = float(i);
        
        float hR = specHist(i, 0.05);
        float hG = specHist(i, 0.3);
        float hB = specHist(i, 0.7);
        
        float hist_ripple = sin(phase + fi * 0.8) * decay;
        
        float displacement_amp = (0.15 + (hR * 1.5)) * isClicked;
        
        float noise = (hash(tc * 50.0 + iTime + fi) - 0.5) * 0.05 * hG * isClicked;
        
        vec2 suvR = tc + dir * hist_ripple * displacement_amp * 3.5 + noise;
        vec2 suvG = tc + dir * hist_ripple * displacement_amp * 1.0;
        vec2 suvB = tc + dir * hist_ripple * displacement_amp * -2.0 - noise;

        vec3 c;
        c.r = cacheHist(i, suvR).r;
        c.g = cacheHist(i, suvG).g;
        c.b = cacheHist(i, suvB).b;
        
        // Lowered the RGB band multipliers from 25.0 down to 10.0
        // This prevents the crests of the wave from clipping out to pure white
        c.r *= 1.0 + (hR * 10.0 * decay * isClicked);
        c.g *= 1.0 + (hG * 10.0 * decay * isClicked);
        c.b *= 1.0 + (hB * 10.0 * decay * isClicked);

        acc += c * pow(0.88, fi);
    }
    
    // Dropped the final accumulation multiplier from 0.35 to 0.12
    // This scales the entire feedback loop down into a visible range
    acc *= 0.12;
    
    color = vec4(clamp(acc, 0.0, 1.0), 1.0);
}