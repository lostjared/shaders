#version 330 core
// Audio-reactive orbital tunnel trails with oldest-cache steering.
in vec2 tc;
out vec4 color;
uniform sampler2D samp, samp1, samp2, samp3, samp4, samp5, samp6, samp7, samp8;
uniform sampler1D spectrum0, spectrum1, spectrum2, spectrum3, spectrum4, spectrum5, spectrum6, spectrum7;
uniform float time_f, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float TAU = 6.28318530718;
vec3 acid(float t) { return 0.5 + 0.5 * cos(TAU * (vec3(0.85, 0.65, 1.0) * t + vec3(0.02, 0.16, 0.32))); }
vec4 cacheHist(int i, vec2 uv) {
    if (i == 0)
        return texture(samp1, uv);
    if (i == 1)
        return texture(samp2, uv);
    if (i == 2)
        return texture(samp3, uv);
    if (i == 3)
        return texture(samp4, uv);
    if (i == 4)
        return texture(samp5, uv);
    if (i == 5)
        return texture(samp6, uv);
    if (i == 6)
        return texture(samp7, uv);
    return texture(samp8, uv);
}
float specHist(int i, float f) {
    if (i == 0)
        return texture(spectrum0, f).r;
    if (i == 1)
        return texture(spectrum1, f).r;
    if (i == 2)
        return texture(spectrum2, f).r;
    if (i == 3)
        return texture(spectrum3, f).r;
    if (i == 4)
        return texture(spectrum4, f).r;
    if (i == 5)
        return texture(spectrum5, f).r;
    if (i == 6)
        return texture(spectrum6, f).r;
    return texture(spectrum7, f).r;
}
vec2 orbitField(vec2 uv, float bass, float mid, float treble, float air, vec3 oldest, float layer) {
    float r = length(uv) + 0.001;
    float a = atan(uv.y, uv.x);
    float spin = a * (4.0 + floor(treble * 5.0)) - r * (11.0 + bass * 10.0) - time_f * (1.8 + mid * 3.5) - layer * 0.6;
    vec2 dir = vec2(cos(spin + a), sin(spin - a));
    dir += vec2(oldest.b - oldest.r, oldest.g - oldest.b) * 0.9;
    return dir * (0.010 + mid * 0.028 + air * 0.020) + uv * -(0.004 + bass * 0.025);
}
void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float bass = texture(spectrum0, 0.03).r, mid = texture(spectrum0, 0.20).r, treble = texture(spectrum0, 0.58).r, air = texture(spectrum0, 0.86).r;
    float hist = 0.0;
    for (int i = 0; i < 8; i++)
        hist += specHist(i, 0.58);
    hist /= 8.0;
    vec2 oldWarp = vec2(cos(time_f * 0.24 + uv.y * 7.0 + hist * 8.0), sin(time_f * 0.27 - uv.x * 7.5 + hist * 6.0)) * (0.012 + hist * 0.028);
    vec3 oldest = texture(samp8, tc + oldWarp).rgb;
    vec2 liveWarp = orbitField(uv, bass, mid, treble, air, oldest, 0.0);
    vec3 live = texture(samp, tc + liveWarp).rgb;
    live *= acid(length(uv) * 0.7 + time_f * 0.07 + bass);
    vec3 accum = live;
    float wsum = 1.0;
    for (int i = 0; i < 8; i++) {
        float layer = float(i + 1);
        float hB = specHist(i, 0.03), hM = specHist(i, 0.20), hT = specHist(i, 0.58), hA = specHist(i, 0.86);
        vec2 drift = orbitField(uv, hB, hM, hT, hA, oldest, layer);
        vec3 cached = cacheHist(i, tc + drift).rgb;
        vec3 tint = acid(layer * 0.10 + hT * 0.8 + oldest.r * 0.2);
        float w = pow(0.80, layer) * (1.0 + hT * 1.3 + hB * 0.4);
        accum += cached * tint * w;
        wsum += w;
    }
    accum /= wsum;
    float ring = smoothstep(0.35, 1.0, abs(sin(length(uv) * 28.0 - time_f * 2.0 + hist * 10.0)));
    accum += acid(time_f * 0.05 + uv.x * 0.2) * ring * (0.08 + amp_smooth * 0.20);
    color = vec4(clamp(mix(accum, vec3(1.0) - accum, smoothstep(0.88, 1.0, amp_peak) * 0.15), 0.0, 1.0), 1.0);
}