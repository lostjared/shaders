#version 330 core
// ant_spectrum_kaleido_rings
// Concentric ring kaleidoscope with mirror folds, echo rings, and spectrum-driven rainbow

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

vec2 kaleidoscope(vec2 p, float seg) {
    float ang = atan(p.y, p.x);
    float r = length(p);
    float s = 2.0 * PI / seg;
    ang = mod(ang, s);
    ang = abs(ang - s * 0.5);
    return vec2(cos(ang), sin(ang)) * r;
}

vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float lowMid = texture(spectrum, 0.12).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Kaleidoscope
    float seg = floor(6.0 + bass * 6.0);
    vec2 kUV = kaleidoscope(uv, seg);
    kUV = abs(kUV);

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Ring density from mid
    float ringDensity = 12.0 + mid * 25.0;
    float ringPattern = sin(r * ringDensity - iTime * 3.0);

    // FIX 1: Remove fract() so the radius grows continuously.
    // Your custom mirror() function needs a continuous, unwrapped number to fold properly.
    float ringR = (r * ringDensity / (2.0 * PI)) + iTime * 0.2;

    // FIX 2: Use abs(angle) to seamlessly bounce the polar wrap instead of letting it snap.
    // This prevents the GPU's mipmapper from tearing the texture when the angle resets.
    vec2 ringUV = vec2(abs(angle) / PI, ringR);
    ringUV = mirror(ringUV);

    // Kaleidoscopic texture sample
    vec2 kTexUV = mirror(kUV * 0.6 + 0.5);
    vec3 kTex = texture(samp, kTexUV).rgb;
    vec3 rTex = texture(samp, ringUV).rgb;

    // Echo rings: samples at different ring depths
    vec3 echoRings = vec3(0.0);
    for (float e = 1.0; e < 5.0; e++) {
        // Apply the same continuous radius and mirrored angle fixes here
        float eR = ((r + e * 0.05) * ringDensity / (2.0 * PI)) + iTime * 0.2;
        vec2 eUV = mirror(vec2(abs(angle) / PI, eR));

        vec3 eSamp = texture(samp, eUV).rgb;
        // Rainbow per ring
        float specFreq = texture(spectrum, e * 0.08 + 0.05).r;
        eSamp *= rainbow(e * 0.2 + r + iTime * 0.25 + specFreq);
        echoRings += eSamp * (0.3 / e);
    }

    // Compose
    vec3 result = mix(kTex, rTex, 0.4 + ringPattern * 0.2);
    result += echoRings;

    // Rainbow ring colors
    vec3 ringColor = rainbow(r * 3.0 + iTime * 0.4 + lowMid);
    result = mix(result, result * ringColor, 0.3 + hiMid * 0.2);

    // Color shift
    result = mix(result, result.brg, treble * 0.4);

    // Ring brightness modulation
    result *= 0.85 + 0.15 * ringPattern;

    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(result, 1.0);
}