#version 330 core
// Floating lantern rings with gentle orbital drag and glowing cache bloom.
in vec2 tc;
out vec4 color;
uniform sampler2D samp, samp1, samp2, samp3, samp4, samp5, samp6, samp7, samp8;
uniform sampler1D spectrum0, spectrum1, spectrum2, spectrum3, spectrum4, spectrum5, spectrum6, spectrum7;
uniform float time_f, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float TAU = 6.28318530718;
vec3 acid(float t) { return 0.5 + 0.5 * cos(TAU * (vec3(1.0, 0.72, 0.52) * t + vec3(0.04, 0.18, 0.31))); }
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
    float wobble = sin(r * 18.0 - time_f * (1.5 + mid * 1.5) + layer * 0.5);
    vec2 dir = vec2(cos(a + wobble * 0.6), sin(a - wobble * 0.6));
    dir += vec2(oldest.r - oldest.g, oldest.b - oldest.g) * 0.6;
    return dir * (0.009 + air * 0.020 + mid * 0.020) + uv * (0.002 + bass * 0.012);
}
void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float bass = texture(spectrum0, 0.04).r, mid = texture(spectrum0, 0.26).r, treble = texture(spectrum0, 0.50).r, air = texture(spectrum0, 0.88).r;
    float hist = 0.0;
    for (int i = 0; i < 8; i++)
        hist += specHist(i, 0.50);
    hist /= 8.0;
    vec3 oldest = texture(samp8, tc + vec2(sin(time_f * 0.16 + uv.y * 4.0), cos(time_f * 0.19 + uv.x * 4.8)) * (0.010 + hist * 0.022)).rgb;
    vec3 live = texture(samp, tc + orbitField(uv, bass, mid, treble, air, oldest, 0.0)).rgb * acid(time_f * 0.05 + air + length(uv) * 0.3);
    vec3 accum = live;
    float wsum = 1.0;
    for (int i = 0; i < 8; i++) {
        float layer = float(i + 1);
        float hB = specHist(i, 0.04), hM = specHist(i, 0.26), hT = specHist(i, 0.50), hA = specHist(i, 0.88);
        vec3 cached = cacheHist(i, tc + orbitField(uv, hB, hM, hT, hA, oldest, layer)).rgb;
        float w = pow(0.83, layer) * (1.0 + hA * 1.0 + hM * 0.5);
        accum += cached * acid(layer * 0.08 + hA * 0.6 + oldest.r * 0.2) * w;
        wsum += w;
    }
    accum /= wsum;
    float glow = smoothstep(0.55, 1.0, abs(sin(length(uv) * 16.0 - time_f * 1.2 + hist * 6.0)));
    accum += vec3(1.0, 0.65, 0.3) * glow * (0.04 + amp_smooth * 0.16);
    color = vec4(clamp(mix(accum, accum.bgr, smoothstep(0.85, 1.0, amp_peak) * 0.10), 0.0, 1.0), 1.0);
}