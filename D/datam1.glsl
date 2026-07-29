#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f; // accumulated time value, affected by speed and audio when enabled
uniform float time_speed; // rate of change to time_f
uniform sampler2D samp; // input video frame texture
uniform vec2 iResolution; // viewport resolution in pixels (width, height)
uniform vec4 iMouse; // mouse position: xy = current, zw = click start (drag)
uniform float amp; // audio amplitude scaled by sensitivity
uniform float uamp; // raw audio amplitude before sensitivity scaling
uniform float iTime; // elapsed wall-clock time in seconds
uniform int iFrame; // current frame number
uniform float iTimeDelta; // time since last frame in seconds
uniform vec4 iDate; // current date/time: (year, month, day, seconds since midnight)
uniform vec2 iMouseClick; // position of last mouse click
uniform float iFrameRate; // target frame rate
uniform vec3 iChannelResolution[4]; // resolution of each texture channel
uniform float iChannelTime[4]; // playback time for each texture channel
uniform float iSampleRate; // audio sample rate in Hz (e.g. 44100)
uniform float amp_peak; // peak absolute sample value in current audio buffer
uniform float amp_rms; // RMS energy of current audio buffer
uniform float amp_smooth; // exponentially smoothed amplitude for gradual transitions
uniform float amp_low; // bass energy (below ~300 Hz)
uniform float amp_mid; // mid-range energy (~300-3000 Hz)
uniform float amp_high; // treble energy (above ~3000 Hz)
uniform float iamp; // estimated dominant frequency in Hz via zero-crossing rate

// pseudo-random hash
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash1(float n) {
    return fract(sin(n) * 43758.5453);
}

void main(void) {
    vec2 uv = tc;
    float aspect = iResolution.x / iResolution.y;

    // clamp audio values
    float aLow   = clamp(amp_low,    0.0, 1.0);
    float aMid   = clamp(amp_mid,    0.0, 1.0);
    float aHigh  = clamp(amp_high,   0.0, 1.0);
    float aPeak  = clamp(amp_peak,   0.0, 1.0);
    float aRms   = clamp(amp_rms,    0.0, 1.0);
    float aSmooth = clamp(amp_smooth, 0.0, 1.0);

    // --- block-based displacement (datamosh core) ---
    // block size shrinks on loud bass, grows on quiet
    float blockSize = mix(0.02, 0.12, aLow);
    vec2 blockUV = floor(uv / blockSize) * blockSize;

    // per-block random seed that changes with time quantized by beat energy
    float timeSeed = floor(time_f * (2.0 + aPeak * 8.0));
    float blockRand = hash(blockUV * 100.0 + timeSeed);

    // displacement direction and magnitude driven by audio
    float displaceStrength = aRms * 0.15 + aPeak * 0.1;
    vec2 blockDisplace = vec2(
        (hash(blockUV + timeSeed) - 0.5) * 2.0,
        (hash(blockUV + timeSeed + 7.0) - 0.5) * 2.0
    ) * displaceStrength;

    // only displace some blocks (more blocks shift on louder audio)
    float threshold = 1.0 - aSmooth * 0.7 - aPeak * 0.3;
    vec2 moshedUV = uv;
    if (blockRand > threshold) {
        moshedUV = uv + blockDisplace;
    }

    // --- pixel smear / stretch on mid energy ---
    float smearAmt = aMid * 0.06;
    float smearDir = hash(blockUV + 3.0);
    if (smearDir > 0.5) {
        moshedUV.x += smearAmt * sign(moshedUV.x - 0.5);
    } else {
        moshedUV.y += smearAmt * sign(moshedUV.y - 0.5);
    }

    // clamp to valid texture coords
    moshedUV = clamp(moshedUV, 0.0, 1.0);

    // --- channel separation driven by high frequency ---
    float chromaShift = aHigh * 0.015 + aPeak * 0.008;
    vec2 rOff = vec2( chromaShift, -chromaShift * 0.5);
    vec2 gOff = vec2(-chromaShift * 0.5,  chromaShift);
    vec2 bOff = vec2(-chromaShift,  chromaShift * 0.5);

    float r = texture(samp, clamp(moshedUV + rOff, 0.0, 1.0)).r;
    float g = texture(samp, clamp(moshedUV + gOff, 0.0, 1.0)).g;
    float b = texture(samp, clamp(moshedUV + bOff, 0.0, 1.0)).b;

    vec3 col = vec3(r, g, b);

    // --- scanline / corruption artifacts on peaks ---
    float scanline = sin(uv.y * iResolution.y * 1.5 + time_f * 20.0);
    float glitchLine = step(0.97 - aPeak * 0.15, abs(scanline));
    col = mix(col, col.gbr, glitchLine * aPeak * 0.6);

    // --- color quantization that loosens with bass ---
    float levels = mix(6.0, 256.0, 1.0 - aLow * 0.8);
    col = floor(col * levels + 0.5) / levels;

    // --- occasional full-block color replace on big peaks ---
    if (aPeak > 0.7 && blockRand > 0.92) {
        vec3 blockCol = texture(samp, blockUV).rgb;
        col = mix(col, blockCol.brg, 0.7);
    }

    color = vec4(col, 1.0);
}

