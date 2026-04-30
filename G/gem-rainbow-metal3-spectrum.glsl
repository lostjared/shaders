#version 330 core
in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;

// Audio variables
uniform float amp_peak; 
uniform float amp_rms; 
uniform float amp_smooth; 
uniform float amp_low; 
uniform float amp_mid; 
uniform float amp_high; 
uniform float iamp; 

// New MIDI/Audio Uniforms
uniform sampler1D spectrum; // 1D FFT audio data (current frame)

// 8 Discrete History Buffers (spectrum0 = newest, spectrum7 = oldest).
// Each frame the engine pushes the latest FFT into spectrum0 and ages the
// rest down, so binding radius -> history index produces rings that physically
// propagate outward as new audio arrives.
uniform sampler1D spectrum0;
uniform sampler1D spectrum1;
uniform sampler1D spectrum2;
uniform sampler1D spectrum3;
uniform sampler1D spectrum4;
uniform sampler1D spectrum5;
uniform sampler1D spectrum6;
uniform sampler1D spectrum7;

uniform float slider1; // Ripple Angle/Complexity
uniform float slider2; // Radial Wave Density
uniform float slider3; // Chromatic Shift Multiplier
uniform float slider4; // FFT Displacement & Glow Mix

// Pick a history buffer by integer index 0..7
float sampleEcho(int index, float freq) {
    if (index <= 0) return texture(spectrum0, freq).r;
    if (index == 1) return texture(spectrum1, freq).r;
    if (index == 2) return texture(spectrum2, freq).r;
    if (index == 3) return texture(spectrum3, freq).r;
    if (index == 4) return texture(spectrum4, freq).r;
    if (index == 5) return texture(spectrum5, freq).r;
    if (index == 6) return texture(spectrum6, freq).r;
    return texture(spectrum7, freq).r;
}

// Broadband energy of a single history shell (a few bins averaged so kicks,
// mids and hats all contribute to that ring lighting up).
float shellEnergyAt(int index) {
    float e = 0.0;
    e += sampleEcho(index, 0.05);
    e += sampleEcho(index, 0.20);
    e += sampleEcho(index, 0.55);
    e += sampleEcho(index, 0.90);
    return e * 0.25;
}

// Renamed from 'spectrum' to avoid sampler1D collision
vec3 colorPalette(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67))));
}

void main(void) {
    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // ECHOMAP: radius -> history index.
    //   r = 0 (center) -> spectrum0 (newest)
    //   r = 1 (edge)   -> spectrum7 (oldest)
    // As frames advance, what was at the center last frame is now at a
    // larger radius -> rings translate outward in time with the audio.
    float historySelect = clamp(r * 7.0, 0.0, 7.0);
    int echoIdx = int(historySelect);
    float echoFrac = fract(historySelect);

    // Per-pixel FFT bin (smoothly blended between two adjacent shells)
    float freqBin = clamp(r * 0.5, 0.0, 1.0);
    float fftA = sampleEcho(echoIdx, freqBin);
    float fftB = sampleEcho(min(echoIdx + 1, 7), freqBin);
    float fft  = mix(fftA, fftB, echoFrac);

    // Energy of THIS shell (drives ring brightness at this radius)
    float energyA = shellEnergyAt(echoIdx);
    float energyB = shellEnergyAt(min(echoIdx + 1, 7));
    float shellEnergy = mix(energyA, energyB, echoFrac);

    // Total instantaneous loudness (gates the whole effect when silent)
    float audioGate = clamp(amp_rms + amp_peak + amp_low + amp_mid + amp_high, 0.0, 1.0);

    // FIX: Force lobes to be a whole number so the circle completes seamlessly
    float lobes = floor(mix(2.0, 40.0, slider1));

    // Ripple rotation driven by audio energy, not pure time.
    float audioPhase = (amp_low + amp_mid) * 6.28318 + time_f * 0.4 * audioGate;
    float ripple = sin(angle * lobes + audioPhase) * (amp_low * 0.08);
    float secondaryLobes = floor(lobes * 2.5);
    ripple += sin(angle * secondaryLobes - audioPhase * 2.0) * (amp_high * 0.05);

    // SLIDER 2: Radial wave density (maps 0.0-1.0 to 5.0-50.0)
    float waveDensity = mix(5.0, 50.0, slider2);

    // Outward-traveling rings. The phase has THREE parts:
    //   * r * waveDensity                 -> spatial ring spacing
    //   * - time_f * scrollSpeed          -> negative-time term: crests move OUTWARD
    //   * + historySelect * 1.2           -> phase locked to the history shell
    //                                        so each shell's audio bumps its ring
    //   * + fft * 12.0 * slider4          -> per-shell FFT distortion
    //
    // Amplitude is gated by the shell's own energy, so a quiet shell's ring
    // is invisible and a loud transient lights up its ring as it travels out.
    float scrollSpeed = 2.0 * (audioGate + amp_peak * 1.5) + 0.15;
    float wave = sin(r * waveDensity
                     - time_f * scrollSpeed
                     + historySelect * 1.2
                     + ripple * 10.0
                     + fft * 12.0 * slider4)
                 * (shellEnergy * 1.8 + audioGate * 0.25);

    // SLIDER 3: Chromatic shift multiplier (maps 0.0-1.0 to 0.1-5.0)
    float shiftMult = mix(0.1, 5.0, slider3);
    float shift = (ripple * 0.5 + wave * 0.05 + fft * 0.05 * slider4)
                * shiftMult * (audioGate + shellEnergy);

    // Chromatic split sampling
    float r_chan = texture(samp, tc + vec2(shift, 0.0)).r;
    float g_chan = texture(samp, tc).g;
    float b_chan = texture(samp, tc - vec2(shift, 0.0)).b;
    vec3 baseTex = vec3(r_chan, g_chan, b_chan);

    // Background rainbow tint follows the history index across the screen
    vec3 rainbow = colorPalette(historySelect * 0.125 + ripple
                                + amp_smooth * 0.3 + (fft * slider4));
    float glowMask = smoothstep(0.5, 1.0, wave) * (shellEnergy + audioGate * 0.5);

    // Per-ring rainbow: each crest of `wave` gets its own hue, advanced by the
    // shell's history index so consecutive rings cycle through the spectrum
    // as they propagate outward.
    float ringPhase = r * waveDensity * 0.15915494   // /(2*pi) -> ring count
                    + historySelect * 0.18
                    + fft * 0.4 * slider4;
    vec3 ringColor  = colorPalette(ringPhase);
    // Push palette toward saturated/vivid colors (subtract grey, scale up).
    ringColor = clamp((ringColor - 0.25) * 1.8, 0.0, 1.0);
    // Wider, sharper crest mask so rings read as solid bands of color.
    float ringMask  = smoothstep(-0.2, 0.8, wave);

    // Central light expands with amp_rms / amp_smooth
    float lightRadius = 6.0 - amp_smooth * 4.0 - amp_rms * 3.0;
    lightRadius = max(lightRadius, 0.5);
    float center = exp(-r * lightRadius);
    float brightness = 1.5 + amp_peak * 2.0;
    vec3 coreGlow = vec3(1.0, 0.98, 0.9) * center * brightness;

    // Mix base texture with rainbow, using SLIDER 4 to boost FFT glow
    vec3 finalColor = mix(baseTex, rainbow,
                          glowMask * (0.35 + amp_rms * 0.3 + (fft * 0.5 * slider4)));

    // Rainbow rings, ~5x brighter than before.
    // Two passes:
    //   1) screen-blend the ring color over the base so it shows even on
    //      bright pixels (instead of clipping to white when added).
    //   2) additive HDR pop on the crests for that neon glow.
    float ringStrength = ringMask * (shellEnergy * 4.0 + audioGate * 1.2 + 0.15);
    vec3 vivid = ringColor * ringStrength * 2.5;
    finalColor = 1.0 - (1.0 - finalColor) * (1.0 - clamp(vivid, 0.0, 1.0)); // screen blend
    finalColor += ringColor * ringStrength * 1.5;                           // additive pop

    finalColor += coreGlow;

    // Add the glitchy wave feedback
    finalColor += (wave * ripple * (2.0 + amp_low * 3.0));

    color = vec4(finalColor, 1.0);
}