#version 330 core
in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform float amp_peak;   // peak absolute sample value in current audio buffer
uniform float amp_rms;    // RMS energy of current audio buffer
uniform float amp_smooth; // exponentially smoothed amplitude for gradual transitions
uniform float amp_low;    // bass energy (below ~300 Hz)
uniform float amp_mid;    // mid-range energy (~300-3000 Hz)
uniform float amp_high;   // treble energy (above ~3000 Hz)
uniform float iamp;       // estimated dominant frequency in Hz via zero-crossing rate
uniform float time_speed;

// High-fidelity spectrum for the oily "fringe" colors
vec3 spectrum(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67))));
}

void main(void) {
    // 1. Setup coordinates
    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    // AUDIO: Peak transients shake the whole image
    float shake = amp_peak * amp_peak * 0.035;
    uv += shake * vec2(sin(time_f * 113.7), cos(time_f * 97.3));

    // AUDIO: Bass breathes the zoom — image pulses in/out with the kick
    float bassZoom = 1.0 + amp_low * 0.6 + amp_peak * 0.35;
    uv /= bassZoom;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // 2. The Zig-Zag Ripples (Complexity)
    // AUDIO: Mids slam the main ripple, highs add fast jitter, bass warps the base frequency
    float rippleFreq = floor(10.0 + amp_low * 15.0 + 0.5);
    float ripple = sin(angle * rippleFreq + time_f + amp_mid * 4.0) * (0.06 + amp_mid * 0.25);
    ripple += sin(angle * 25.0 - time_f * 2.0 + amp_high * 8.0) * (0.03 + amp_high * 0.15);
    ripple += sin(angle * 50.0 + time_f * 5.0) * amp_peak * 0.12;

    // 3. Radial Wave Logic
    // AUDIO: Bass hammers waves outward, mids add secondary wave, peak adds shockwave
    float waveSpeed = 4.0 + amp_rms * 8.0;
    float waveFreq = 20.0 + amp_mid * 20.0;
    float wave = sin(r * waveFreq - time_f * waveSpeed - amp_low * 14.0 + ripple * 15.0);
    wave += sin(r * 40.0 + time_f * 3.0 - amp_peak * 10.0) * amp_peak * 0.6;

    // AUDIO: Mids distort UV coordinates — the geometry itself warps with the music
    vec2 warpOffset = vec2(
        sin(r * 8.0 - time_f * 2.0) * amp_mid * 0.06,
        cos(r * 8.0 + time_f * 1.5) * amp_mid * 0.06);
    vec2 warpedTC = tc + warpOffset + vec2(ripple * amp_low * 0.3);

    // 4. Chromatic Aberration Distortion
    // AUDIO: Massive RGB split — treble + peak tear the channels apart, bass adds drift
    float shift = ripple * 0.8 + wave * 0.025 + amp_high * 0.07 + amp_peak * 0.06 + amp_low * 0.02;

    // AUDIO: Each channel gets a rotated split direction for swirl aberration
    float splitAngle = amp_mid * 0.6;
    vec2 splitDir = vec2(cos(splitAngle), sin(splitAngle));
    vec2 splitDirN = vec2(cos(-splitAngle), sin(-splitAngle));

    float r_chan = texture(samp, warpedTC + splitDir * shift).r;
    float g_chan = texture(samp, warpedTC).g;
    float b_chan = texture(samp, warpedTC - splitDirN * shift).b;
    vec3 baseTex = vec3(r_chan, g_chan, b_chan);

    // 5. Psychedelic Coloring
    // AUDIO: Smooth + mids accelerate color cycling hard, bass shifts the palette origin
    vec3 rainbow = spectrum(r - time_f * 0.5 - amp_smooth * 6.0 - amp_mid * 2.0 + ripple + amp_low * 1.5);
    // AUDIO: Peak widens the glow bands so more of the image goes psychedelic
    float glowMask = smoothstep(0.2 - amp_peak * 0.05, 1.0, wave);

    // AUDIO: Hue rotation driven by smooth energy — entire palette shifts with volume
    float hueShift = amp_smooth * 2.0 + amp_mid * 1.2;
    float cosH = cos(hueShift), sinH = sin(hueShift);
    mat3 hueRot = mat3(
        0.577 + 0.816 * cosH + 0.057 * sinH, 0.577 - 0.577 * cosH - 0.577 * sinH, 0.577 - 0.240 * cosH + 0.520 * sinH,
        0.577 - 0.240 * cosH + 0.520 * sinH, 0.577 + 0.816 * cosH + 0.057 * sinH, 0.577 - 0.577 * cosH - 0.577 * sinH,
        0.577 - 0.577 * cosH - 0.577 * sinH, 0.577 - 0.240 * cosH + 0.520 * sinH, 0.577 + 0.816 * cosH + 0.057 * sinH);
    rainbow = hueRot * rainbow;

    // 6. Central Highlight
    // AUDIO: Bass blows the core wide open, peak makes it blinding, mids add pulsing rings
    float center = exp(-r * 6.0) + exp(-r * 1.5) * amp_low * 1.2;
    center += sin(r * 12.0 - time_f * 3.0) * amp_mid * 0.3;
    vec3 coreGlow = vec3(1.0, 0.98, 0.9) * center * (1.0 + amp_peak * 1.5 + amp_low * 0.75);

    // 7. Final Composite
    // AUDIO: Peak + RMS dramatically increase the psychedelic rainbow blend
    float rainbowMix = (glowMask * time_speed) + 0.1 * (0.5 + amp_peak * 0.8 + amp_rms * 0.4);
    vec3 finalColor = mix(baseTex, rainbow, clamp(rainbowMix, 0.0, 1.0));
    finalColor += coreGlow;

    // AUDIO: Metallic sheen cranked — RMS + peak make edges flash like lightning
    finalColor += wave * ripple * (4.0 + amp_rms * 16.0 + amp_peak * 10.0);

    // AUDIO: Saturation pump — louder music = more vivid color
    float grey = dot(finalColor, vec3(0.299, 0.587, 0.114));
    float satBoost = 1.0 + amp_rms * 1.8 + amp_peak * 0.8;
    finalColor = mix(vec3(grey), finalColor, satBoost);

    // AUDIO: Brightness slam + contrast curve on hits
    float bright = 1.0 + amp_peak * 1.4 + amp_low * 0.5;
    finalColor = pow(max(finalColor * bright, 0.0), vec3(1.0 + amp_peak * 0.4));

    // AUDIO: Bass-reactive vignette — edges crush dark on heavy hits
    float vignette = 1.0 - length((tc - 0.5) * 1.6) * (0.25 + amp_low * 0.9);
    finalColor *= clamp(vignette, 0.0, 1.0);

    color = vec4(clamp(finalColor, 0.0, 1.0), 1.0);
}