#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// A simple hash for the "snow"
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    // 1. Audio Data (Signal Interference Strength)
    float bass = texture(spectrum, 0.05).r;
    float treble = texture(spectrum, 0.60).r;
    
    // Signal strength inversely tied to audio intensity
    float signalLoss = clamp(bass + treble * 0.5, 0.0, 1.0);

    vec2 uv = tc;

    // 2. Horizontal Sync Wobble (Horizontal tearing)
    // Occurs when the antenna loses horizontal lock
    float wobble = sin(uv.y * 10.0 + time_f * 2.0) * 0.01 * signalLoss;
    uv.x += wobble + (hash(vec2(time_f, uv.y)) - 0.5) * 0.005 * signalLoss;

    // 3. Multipath Interference (Ghosting)
    // We sample the texture multiple times with different offsets
    vec3 col = texture(samp, uv).rgb;
    vec3 ghost1 = texture(samp, uv + vec2(0.015, 0.005)).rgb;
    vec3 ghost2 = texture(samp, uv + vec2(0.03, -0.01)).rgb;
    
    // Mix ghosts in with low opacity
    col = mix(col, ghost1, 0.2 * signalLoss);
    col = mix(col, ghost2, 0.1 * signalLoss);

    // 4. AC Hum Bars (60Hz Interference)
    // Dark bands that crawl vertically due to power line interference
    float humBar = sin(uv.y * 5.0 - time_f * 1.2);
    humBar = smoothstep(0.5, 1.0, humBar);
    col *= 1.0 - (humBar * 0.15);

    // 5. RF Snow (Static)
    // High-frequency "salt and pepper" noise
    float snow = hash(uv + time_f);
    col = mix(col, vec3(snow), 0.1 + signalLoss * 0.3);

    // 6. Vertical Roll (Sync Drop)
    // Every now and then, the signal "slips" vertically
    float roll = fract(uv.y + time_f * 0.1 * step(0.98, hash(vec2(floor(time_f)))));
    // (Uncomment the line below to enable the vertical slip effect)
    // uv.y = mix(uv.y, roll, signalLoss * 0.1);

    // 7. Analog Color Decay (B&W / Faded Color)
    // Weak antenna signals often lose their color burst first
    float luma = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(col, vec3(luma), 0.5 + signalLoss * 0.5);

    // 8. Vignette (Tube Curvature)
    float vig = smoothstep(0.8, 0.3, length(tc - 0.5));
    col *= (vig + 0.2);

    color = vec4(col, 1.0);
}