#version 330 core
// ant_gem_metal_weave
// Woven metallic threads with over-under pattern and spectrum-driven shimmer

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

vec3 metalSpectrum(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67))));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main(void) {
    float bass = texture(spectrum, 0.04).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Weave grid with two thread directions
    float weaveScale = 10.0 + bass * 5.0;
    vec2 rotUV = rot(0.785) * uv; // 45 degree rotation

    // Warp threads
    float warpThread = sin(uv.y * weaveScale + time_f * 2.0) * 0.5 + 0.5;
    float weftThread = sin(rotUV.x * weaveScale - time_f * 1.5) * 0.5 + 0.5;

    // Over-under pattern
    float warpID = floor(uv.y * weaveScale + time_f * 2.0 + 0.5);
    float weftID = floor(rotUV.x * weaveScale - time_f * 1.5 + 0.5);
    float overUnder = mod(warpID + weftID, 2.0);

    // Thread width
    float threadWidth = 0.6 + treble * 0.2;
    float warpMask = smoothstep(threadWidth, threadWidth + 0.1, warpThread) +
                     smoothstep(1.0 - threadWidth, 1.0 - threadWidth - 0.1, warpThread);
    warpMask = 1.0 - warpMask;
    float weftMask = smoothstep(threadWidth, threadWidth + 0.1, weftThread) +
                     smoothstep(1.0 - threadWidth, 1.0 - threadWidth - 0.1, weftThread);
    weftMask = 1.0 - weftMask;

    // Combine with depth ordering
    float topThread = mix(warpMask, weftMask, overUnder);
    float shadow = mix(weftMask, warpMask, overUnder) * 0.3;

    // Texture warp along threads
    float threadWarp = topThread * 0.02;
    vec2 sampUV = tc + vec2(threadWarp * sin(angle), threadWarp * cos(angle));

    // Chromatic split
    float chroma = 0.008 + air * 0.02;
    vec3 baseTex;
    baseTex.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    baseTex.g = texture(samp, sampUV).g;
    baseTex.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Metallic thread coloring
    vec3 warpColor = metalSpectrum(warpID * 0.1 + time_f * 0.15);
    vec3 weftColor = metalSpectrum(weftID * 0.1 + time_f * 0.2 + 0.5);
    vec3 threadColor = mix(warpColor, weftColor, overUnder);

    vec3 finalColor = mix(baseTex, baseTex * threadColor, topThread * (0.4 + hiMid * 0.4));
    finalColor *= 1.0 - shadow * (0.3 + mid * 0.2); // shadow under bottom thread

    // Shimmer on thread surfaces
    float shimmer = pow(sin(uv.x * 50.0 + uv.y * 50.0 + time_f * 4.0) * 0.5 + 0.5, 8.0);
    finalColor += threadColor * shimmer * air * topThread * 1.5;

    // Central glow
    float center = exp(-r * (5.0 - amp_smooth * 3.0));
    finalColor += vec3(1.0, 0.97, 0.93) * center * (1.3 + amp_peak * 1.8);

    color = vec4(finalColor, 1.0);
}
