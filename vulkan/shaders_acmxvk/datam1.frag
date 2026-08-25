#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp ext.u1.y
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iChannelTime ext.custom_uniforms[3].x
#define iFrame int(ext.u2.x)
#define iFrameRate ext.u1.w
#define iMouse ext.mouse
#define iMouseClick ext.mouse.xy
#define iResolution ext.u0.zw
#define iSampleRate ext.u2.z
#define iTime ext.u0.y
#define iTimeDelta ext.u1.x
#define iamp ext.u1.z
#define time_f ext.u2.y
#define time_speed ext.custom_uniforms[3].y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;


layout(set = 0, binding = 0) uniform sampler2D samp; // input video frame texture







uniform vec4 iDate;


uniform vec3 iChannelResolution[4]; // resolution of each texture channel










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

