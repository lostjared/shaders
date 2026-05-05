#version 330 core
// ant_gem_metal_chrome
// Chrome reflection distortion with spectrum-driven warp and metallic sheen

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
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Chrome warp: reflection-like distortion driven by bass
    vec2 warp = uv;
    warp = rot(sin(r * 6.0 - time_f * 2.0) * (0.3 + bass * 0.5)) * warp;
    warp += sin(warp.yx * (5.0 + mid * 8.0) + time_f) * (0.05 + treble * 0.04);

    // Map warped coords back to texture space
    vec2 sampUV = warp * 0.5 + 0.5;

    // Chromatic aberration: chrome splits light
    float chroma = 0.01 + air * 0.03 + amp_peak * 0.02;
    vec3 baseTex;
    baseTex.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    baseTex.g = texture(samp, sampUV).g;
    baseTex.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Chrome reflectivity: desaturate and boost contrast
    float luma = dot(baseTex, vec3(0.299, 0.587, 0.114));
    vec3 chrome = mix(vec3(luma), baseTex, 0.3 + mid * 0.4);
    chrome = pow(chrome, vec3(0.8)); // boost highlights

    // Metallic rainbow edge
    float edge = abs(sin(r * (15.0 + bass * 10.0) - time_f * 3.0));
    vec3 rainbow = metalSpectrum(angle / 6.28318 + time_f * 0.2 + r);
    chrome = mix(chrome, chrome * rainbow, edge * (0.3 + treble * 0.3));

    // Central glow
    float lightRadius = 5.0 - amp_smooth * 3.5;
    float center = exp(-r * max(lightRadius, 0.5));
    vec3 coreGlow = vec3(1.0, 0.98, 0.95) * center * (1.5 + amp_peak * 2.0);

    vec3 finalColor = chrome + coreGlow;
    finalColor *= 0.9 + amp_smooth * 0.3;

    color = vec4(finalColor, 1.0);
}
