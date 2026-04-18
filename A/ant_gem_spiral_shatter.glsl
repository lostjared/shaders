#version 330 core
// ant_gem_spiral_shatter
// Metal-style spiral with fractal shattering and chromatic explosion on beats

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

vec3 metalPalette(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67))));
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= aspect;

    // Peak-driven screen shake
    float shake = amp_peak * amp_peak * 0.03;
    uv += shake * vec2(sin(iTime * 113.7), cos(iTime * 97.3));

    // Bass breathing zoom
    uv /= 1.0 + bass * 0.5;

    float r = length(uv);

    // Use continuous uv-based angle proxies (no atan discontinuity)
    vec2 dir = uv / (r + 0.001);

    // Spiral distortion using continuous sin/cos of angle
    float spiralTight = 2.0 + bass * 8.0 + amp_peak * 4.0;
    float spiralPhase = log(r + 0.1) * spiralTight - iTime * 1.5;

    // Fractal shattering: sine-warp distortion (no axis-aligned folds)
    vec2 shardUV = uv;
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        float a = spiralPhase * 0.1 + fi * 0.4;
        shardUV = rot(a) * shardUV;
        shardUV += vec2(sin(shardUV.y * 3.0 + iTime + fi),
                        cos(shardUV.x * 3.0 - iTime + fi)) * (0.35 + hiMid * 0.15);
    }

    // Map shattered coords to texture via smooth cosine fold
    vec2 rawUV = shardUV * 0.3 + 0.5;

    // Ripples based on continuous uv (no atan seam)
    float ripple = sin(dot(uv, vec2(5.0 + bass * 6.0, 3.0)) + iTime + mid * 3.0) * 0.04;
    ripple += sin(dot(uv, vec2(-3.0, 7.0 + treble * 4.0)) - iTime * 2.0 + treble * 6.0) * 0.02;
    rawUV += ripple;

    // Smooth cosine wrap: infinitely differentiable, no seams
    vec2 sampUV = 0.5 + 0.5 * cos(rawUV * PI);

    // Massive chromatic explosion on peaks
    float chromaBase = treble * 0.04 + amp_peak * 0.06;
    float splitAngle = mid * 0.5;
    vec2 splitDir = vec2(cos(splitAngle), sin(splitAngle));
    vec3 col;
    col.r = texture(samp, 0.5 + 0.5 * cos((rawUV + splitDir * chromaBase) * PI)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, 0.5 + 0.5 * cos((rawUV - splitDir * chromaBase) * PI)).b;

    // Metal spiral color overlay (use continuous dir instead of angle)
    float colFreq = 3.0 + treble * 10.0;
    vec3 spiralCol = metalPalette(spiralPhase * 0.1 + r + dot(dir, vec2(0.7, 0.7)) - iTime * 0.3);
    float ringMask = sin(r * (20.0 + mid * 15.0) - iTime * 3.0);
    col = mix(col, col * spiralCol, 0.35 + hiMid * 0.25);

    // Metallic sheen on wave crests
    col += ringMask * ripple * (3.0 + amp_smooth * 8.0);

    // Center glow
    float coreGlow = exp(-r * 5.0) * (1.0 + bass * 1.5);
    col += vec3(1.0, 0.95, 0.85) * coreGlow * 0.3;

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
