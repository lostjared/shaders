#version 330 core
// ant_gem_ice_ripple
// Ripple distortion with ice-blue crystal palette and reflective facets

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

vec3 ice(float t) {
    vec3 a = vec3(0.6, 0.7, 0.9);
    vec3 b = vec3(0.2, 0.3, 0.4);
    vec3 c = vec3(1.0, 1.2, 1.5);
    vec3 d = vec3(0.2, 0.3, 0.5);
    return a + b * cos(6.28318 * (c * t + d));
}

vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    // Moving center that drifts with spectrum
    float t = iTime * 0.4;
    float t_floor = floor(t);
    float t_fract = smoothstep(0.0, 1.0, fract(t));
    vec2 p0 = fract(sin(vec2(t_floor, t_floor + 1.0)) * vec2(43758.5453, 12345.6789));
    vec2 p1 = fract(sin(vec2(t_floor + 1.0, t_floor + 2.0)) * vec2(43758.5453, 12345.6789));
    vec2 center = mix(p0, p1, t_fract);

    vec2 uv = tc - center;
    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Bass-pulsed swirl
    float swirl = (sin(iTime * 0.3) * 2.5 + bass * 3.0) * exp(-r * 2.0);
    angle += swirl;

    // Crystal facet folding
    float segments = 4.0 + floor(hiMid * 6.0);
    float step_val = 6.28318 / segments;
    angle = mod(angle, step_val);
    angle = abs(angle - step_val * 0.5);

    // Reconstruct with facets
    vec2 warpedUV = center + vec2(cos(angle), sin(angle)) * r;

    // Liquid ripple waves
    float rippleStr = 0.015 * (1.0 + mid * 2.0);
    warpedUV += rippleStr * vec2(
                                sin(tc.y * 12.0 + iTime * 3.0 + bass * 5.0),
                                cos(tc.x * 12.0 + iTime * 3.0 + mid * 5.0));

    // Mirror-wrap coordinates
    warpedUV = mirror(warpedUV);

    // Ice chromatic split
    float shift = (treble + air) * 0.04;
    vec3 col;
    col.r = texture(samp, warpedUV + shift * 0.7).r;
    col.g = texture(samp, warpedUV).g;
    col.b = texture(samp, warpedUV - shift * 0.5).b;

    // Ice palette overlay
    vec3 iceCol = ice(r * 3.0 - iTime * 0.2 + bass);
    col = mix(col, col * iceCol, 0.3 + mid * 0.25);

    // Frost crystal highlights
    float frost = pow(max(0.0, sin(r * 30.0 + angle * segments - iTime * 2.0)), 8.0);
    col += vec3(0.7, 0.85, 1.0) * frost * 0.3 * (1.0 + treble);

    // Focus vignette
    float vignette = smoothstep(1.2, 0.2, r);
    col *= vignette;

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
