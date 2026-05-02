#version 330 core
// Remix: gem_polar (log-polar warp) + gem-spiral-frac (spiral fold) + gem_rainbow_spectrum (chromatic aberration)
// Spectrum drives: wormhole pull (bass), spiral arm count (mid sweep), aberration magnitude (treble)
// Creates a wormhole that breathes and spirals with the music

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

vec3 palette(float t) {
    vec3 a = vec3(0.5);
    vec3 b = vec3(0.5);
    vec3 c = vec3(1.0);
    vec3 d = vec3(0.30, 0.20, 0.20);
    return a + b * cos(6.28318 * (c * t + d));
}

void main() {
    // Dense 8-band spectrum sampling
    float sub = texture(spectrum, 0.01).r;
    float bass = texture(spectrum, 0.04).r;
    float lowMid = texture(spectrum, 0.10).r;
    float mid = texture(spectrum, 0.20).r;
    float hiMid = texture(spectrum, 0.32).r;
    float pres = texture(spectrum, 0.45).r;
    float treble = texture(spectrum, 0.60).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // === Wormhole pull: bass contracts the center ===
    float pull = 1.0 + bass * 2.0;
    float warpR = pow(r, 0.7 + sub * 0.3) * pull;

    // === Spiral arms from gem-spiral-frac ===
    float armCount = 3.0 + mid * 5.0;
    float spiralTwist = angle + log(warpR + 0.001) * (2.0 + lowMid * 3.0) - iTime * (0.5 + bass);
    float spiralPattern = sin(spiralTwist * armCount);
    float spiralMask = smoothstep(-0.2, 0.2, spiralPattern);

    // Spiral fold distortion on UV
    vec2 spiralUV = uv;
    spiralUV *= rot(spiralPattern * (0.1 + hiMid * 0.3));

    // === Log-polar wormhole tunnel from gem_polar ===
    float tunnelSpeed = 0.5 + bass * 1.5;
    vec2 tunnelUV;
    tunnelUV.x = angle / PI;
    tunnelUV.y = 1.0 / (warpR + 0.01) + iTime * tunnelSpeed;

    // Fold for seamless wrap
    vec2 wrapUV = abs(fract(tunnelUV * 0.5) * 2.0 - 1.0);

    // === Chromatic aberration from gem_rainbow_spectrum ===
    float abr = (0.01 + treble * 0.05) * (1.0 + pres * 0.5);
    vec2 chrDir = normalize(uv + 0.001);
    vec3 tex;
    tex.r = texture(samp, wrapUV + chrDir * abr).r;
    tex.g = texture(samp, wrapUV).g;
    tex.b = texture(samp, wrapUV - chrDir * abr).b;

    // Also sample with spiral distortion
    vec2 spiralTexUV = fract(spiralUV * 0.3 + 0.5);
    vec4 spiralTex = texture(samp, spiralTexUV);

    // === Event horizon ring ===
    float ringR = 0.15 + sub * 0.05;
    float ringGlow = exp(-pow((r - ringR) * 15.0, 2.0));
    vec3 horizonColor = palette(angle / PI + iTime * 0.5 + mid);

    // === Compose ===
    // Inside horizon: tunnel texture; outside: spiral texture
    float horizonBlend = smoothstep(ringR - 0.1, ringR + 0.1, r);
    vec3 result = mix(tex, spiralTex.rgb, horizonBlend * spiralMask);

    // Arm glow from palette
    result += spiralMask * 0.15 * palette(angle / PI + r + iTime * 0.2);

    // Event horizon ring
    result += ringGlow * horizonColor * (1.0 + bass * 1.5);

    // Center bright core
    float core = exp(-r * (6.0 - bass * 3.0));
    result += core * vec3(1.0, 0.95, 0.85) * (0.5 + sub * 0.8);

    // Air frequency adds sparkling edge
    result += air * 0.08 * vec3(0.6, 0.8, 1.0) * sin(angle * 40.0 + iTime * 10.0);

    // Vignette
    result *= smoothstep(2.0, 0.4, r);

    // Peak: brief whiteout flash
    result += amp_peak * 0.3;

    color = vec4(result, 1.0);
}
