#version 330 core
// ant_gem_chrome_wave
// Metal zigzag ripples with chrome reflection and radial wave patterns

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

vec3 chrome(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.1, 0.2))));
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc * 2.0 - 1.0);
    uv.x *= aspect;

    // Bass-driven zoom pulse
    uv /= 1.0 + bass * 0.45;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Zigzag angular ripples (from metal shader)
    float rippleFreq = floor(10.0 + bass * 12.0 + 0.5);
    float ripple = sin(angle * rippleFreq + iTime + mid * 3.0) * (0.05 + mid * 0.2);
    ripple += sin(angle * 25.0 - iTime * 2.0 + treble * 6.0) * (0.02 + treble * 0.12);

    // Radial wave
    float waveSpeed = 3.0 + amp_smooth * 6.0;
    float waveFreq = 18.0 + mid * 15.0;
    float wave = sin(r * waveFreq - iTime * waveSpeed - bass * 10.0 + ripple * 12.0);

    // UV warp
    vec2 warpOff = vec2(
        sin(r * 7.0 - iTime * 1.5) * mid * 0.05,
        cos(r * 7.0 + iTime * 1.2) * mid * 0.05
    );
    vec2 warpedTC = tc + warpOff + vec2(ripple * bass * 0.25);

    // Chrome chromatic aberration
    float shift = ripple * 0.6 + wave * 0.02 + treble * 0.05 + amp_peak * 0.04;
    float splitAngle = mid * 0.5;
    vec2 splitDir = vec2(cos(splitAngle), sin(splitAngle));
    vec3 col;
    col.r = texture(samp, warpedTC + splitDir * shift).r;
    col.g = texture(samp, warpedTC).g;
    col.b = texture(samp, warpedTC - splitDir * shift).b;

    // Chrome reflection overlay
    vec3 chromeCol = chrome(r - iTime * 0.3 - amp_smooth * 2.0 + ripple + bass);
    float chromeMask = smoothstep(0.2 - amp_peak * 0.04, 1.0, wave);
    col = mix(col, col * chromeCol, chromeMask * 0.4);

    // Metallic sheen on wave crests
    col += wave * ripple * (3.0 + amp_smooth * 10.0);

    // Saturation boost
    float grey = dot(col, vec3(0.299, 0.587, 0.114));
    float satBoost = 1.0 + amp_smooth * 1.2 + amp_peak * 0.5;
    col = mix(vec3(grey), col, satBoost);

    // Center highlight
    float coreGlow = exp(-r * 5.0) * (1.0 + bass);
    col += vec3(0.95, 0.95, 1.0) * coreGlow * 0.25;

    // Bass vignette
    float vignette = 1.0 - length((tc - 0.5) * 1.6) * (0.3 + bass * 0.6);
    col *= clamp(vignette, 0.0, 1.0);

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
