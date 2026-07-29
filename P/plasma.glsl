#version 330 core

in vec2 tc;
out vec4 color;
uniform float time_f;
uniform vec2 iResolution;
float PI = 3.1415926535897932384626433832795;
uniform sampler2D samp;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;


void main() {
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= iResolution.x / iResolution.y;
    float plasma = 0.0;
    float pFreq = 5.0 + amp_mid * 10.0;
    plasma += sin((uv.x + time_f) * pFreq);
    plasma += sin((uv.y + time_f) * pFreq);
    plasma += sin((uv.x + uv.y + time_f) * pFreq);
    plasma += cos(length(uv + time_f) * (10.0 + amp_low * 15.0));
    plasma *= 0.25;
    vec3 col;
    col.r = cos(plasma * PI + time_f * 0.2) * 0.5 + 0.5;
    col.g = sin(plasma * PI + time_f * 0.2) * 0.5 + 0.5;
    col.b = sin(plasma * PI + time_f * 0.4) * 0.5 + 0.5;

    // --- Audio Reactivity: direct output modulation ---
    float _ab = clamp(amp_peak, 0.0, 1.0);
    float _abass = clamp(amp_low, 0.0, 1.0);
    col *= 1.0 + _ab * 0.6;
    col = mix(col, col * vec3(1.0 + _abass * 0.3, 1.0 - _abass * 0.15, 1.0 + clamp(amp_high, 0.0, 1.0) * 0.25), _ab);
    // --- End Audio Reactivity ---

    color = vec4(col, 1.0);
    color = mix(color, texture(samp, tc), 0.5);
}

