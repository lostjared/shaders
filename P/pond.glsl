#version 330 core
// ant_cache_spectrum8_chromatic_pulse_water_splash_mouse_10x_darker
// Extreme rippling displacement with aggressive chromatic tearing and noise, brightness tamed

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler2D samp1;
uniform sampler2D samp2;
uniform sampler2D samp3;
uniform sampler2D samp4;
uniform sampler2D samp5;
uniform sampler2D samp6;
uniform sampler2D samp7;
uniform sampler2D samp8;

uniform sampler1D spectrum0;
uniform sampler1D spectrum1;
uniform sampler1D spectrum2;
uniform sampler1D spectrum3;
uniform sampler1D spectrum4;
uniform sampler1D spectrum5;
uniform sampler1D spectrum6;
uniform sampler1D spectrum7;

uniform float iTime;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp_peak;
uniform float amp_smooth;

const float TAU = 6.28318530718;
const float PI  = 3.14159265359;

float specHist(int i, float f) {
    if (i == 0) return texture(spectrum0, f).r;
    if (i == 1) return texture(spectrum1, f).r;
    if (i == 2) return texture(spectrum2, f).r;
    if (i == 3) return texture(spectrum3, f).r;
    if (i == 4) return texture(spectrum4, f).r;
    if (i == 5) return texture(spectrum5, f).r;
    if (i == 6) return texture(spectrum6, f).r;
    return texture(spectrum7, f).r;
}

vec4 cacheHist(int i, vec2 uv) {
    if (i == 0) return texture(samp,  uv);
    if (i == 1) return texture(samp1, uv);
    if (i == 2) return texture(samp2, uv);
    if (i == 3) return texture(samp3, uv);
    if (i == 4) return texture(samp4, uv);
    if (i == 5) return texture(samp5, uv);
    if (i == 6) return texture(samp6, uv);
    if (i == 7) return texture(samp7, uv);
    return texture(samp8, uv);
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