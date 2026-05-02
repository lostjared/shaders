#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;               // accumulated time value, affected by speed and audio when enabled
uniform float time_speed;           // rate of change to time_f
uniform sampler2D samp;             // input video frame texture
uniform vec2 iResolution;           // viewport resolution in pixels (width, height)
uniform vec4 iMouse;                // mouse position: xy = current, zw = click start (drag)
uniform float amp;                  // audio amplitude scaled by sensitivity
uniform float uamp;                 // raw audio amplitude before sensitivity scaling
uniform float iTime;                // elapsed wall-clock time in seconds
uniform int iFrame;                 // current frame number
uniform float iTimeDelta;           // time since last frame in seconds
uniform vec4 iDate;                 // current date/time: (year, month, day, seconds since midnight)
uniform vec2 iMouseClick;           // position of last mouse click
uniform float iFrameRate;           // target frame rate
uniform vec3 iChannelResolution[4]; // resolution of each texture channel
uniform float iChannelTime[4];      // playback time for each texture channel
uniform float iSampleRate;          // audio sample rate in Hz (e.g. 44100)
uniform float amp_peak;             // peak absolute sample value in current audio buffer
uniform float amp_rms;              // RMS energy of current audio buffer
uniform float amp_smooth;           // exponentially smoothed amplitude for gradual transitions
uniform float amp_low;              // bass energy (below ~300 Hz)
uniform float amp_mid;              // mid-range energy (~300-3000 Hz)
uniform float amp_high;             // treble energy (above ~3000 Hz)
uniform float iamp;                 // estimated dominant frequency in Hz via zero-crossing rate

mat2 rotate(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

vec2 mirror(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    vec2 centered = tc - 0.5;
    float dist = length(centered);

    // Bass pulse: radial breathing that throbs with low frequencies
    float bassPulse = 1.0 + amp_low * 0.35 * sin(dist * 14.0 - time_f * 4.0);
    centered *= bassPulse;

    // Kaleidoscope: segment count driven by RMS energy
    float segments = floor(mix(3.0, 10.0, clamp(amp_rms * 4.0, 0.0, 1.0)));
    float segAngle = 6.2831853 / segments;
    float kalAngle = atan(centered.y, centered.x);
    float kalDist = length(centered);
    kalAngle = mod(kalAngle, segAngle);
    kalAngle = abs(kalAngle - segAngle * 0.5);
    centered = kalDist * vec2(cos(kalAngle), sin(kalAngle));

    // Mid-range rotation: spin speed driven by mids
    float rotAmount = time_f * (0.3 + amp_mid * 2.5) + amp_mid * 1.5;
    centered = rotate(rotAmount) * centered;

    // Drifting mirror origin from smoothed amplitude
    vec2 drift = amp_smooth * 0.2 * vec2(sin(time_f * 0.8), cos(time_f * 0.6));
    vec2 uv = mirror(centered + 0.5 + drift);

    // Peak ripple: concentric wave on loud transients
    float ripple = amp_peak * sin(dist * 35.0 - time_f * 10.0) * 0.025;
    uv += ripple * normalize(centered + 0.001);

    // Chromatic aberration driven by treble energy
    float chroma = amp_high * 0.02;
    vec2 chromaDir = normalize(centered + 0.001);
    float r = texture(samp, clamp(uv + chromaDir * chroma, 0.0, 1.0)).r;
    float g = texture(samp, clamp(uv, 0.0, 1.0)).g;
    float b = texture(samp, clamp(uv - chromaDir * chroma, 0.0, 1.0)).b;

    color = vec4(r, g, b, 1.0);

    // Brightness flash on peaks
    color.rgb += smoothstep(0.6, 1.0, amp_peak) * 0.3;

    // Subtle color tint shift per frequency band
    color.r += amp_low * 0.05;
    color.b += amp_high * 0.05;
}
