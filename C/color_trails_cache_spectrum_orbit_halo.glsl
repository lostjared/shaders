#version 330 core
// Halo-like circular trails that breathe with upper-spectrum energy.
in vec2 tc;
out vec4 color;
uniform sampler2D samp, samp1, samp2, samp3, samp4, samp5, samp6, samp7, samp8;
uniform sampler1D spectrum0, spectrum1, spectrum2, spectrum3, spectrum4, spectrum5, spectrum6, spectrum7;
uniform float time_f, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float TAU = 6.28318530718;
vec3 acid(float t) { return 0.5 + 0.5 * cos(TAU * (vec3(0.62, 0.92, 1.0) * t + vec3(0.06, 0.26, 0.44))); }
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
    float pulse = sin(r * (24.0 + air * 16.0) - time_f * (2.6 + treble * 2.4) - layer * 0.7);
    vec2 dir = vec2(cos(a + 0.5 * pulse), sin(a - 0.5 * pulse));
    dir += vec2(oldest.g - oldest.r, oldest.g - oldest.b) * 0.7;
    return dir * (0.010 + air * 0.026 + treble * 0.015) + normalize(uv + 0.0001) * pulse * (0.004 + bass * 0.02);
}
void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float bass = texture(spectrum0, 0.03).r, mid = texture(spectrum0, 0.22).r, treble = texture(spectrum0, 0.66).r, air = texture(spectrum0, 0.94).r;
    float hist = 0.0;
    for (int i = 0; i < 8; i++)
        hist += specHist(i, 0.94);
    hist /= 8.0;
    vec3 oldest = texture(samp8, tc + vec2(sin(time_f * 0.2 + uv.y * 5.0), cos(time_f * 0.22 + uv.x * 5.5)) * (0.010 + hist * 0.035)).rgb;
    vec3 live = texture(samp, tc + orbitField(uv, bass, mid, treble, air, oldest, 0.0)).rgb * acid(length(uv) * 0.4 + air + time_f * 0.06);
    vec3 accum = live;
    float wsum = 1.0;
    for (int i = 0; i < 8; i++) {
        float layer = float(i + 1);
        float hB = specHist(i, 0.03), hM = specHist(i, 0.22), hT = specHist(i, 0.66), hA = specHist(i, 0.94);
        vec3 cached = cacheHist(i, tc + orbitField(uv, hB, hM, hT, hA, oldest, layer)).rgb;
        float w = pow(0.82, layer) * (1.0 + hA * 1.35);
        accum += cached * acid(layer * 0.09 + hA * 0.8 + oldest.g * 0.3) * w;
        wsum += w;
    }
    accum /= wsum;
    float halo = smoothstep(0.6, 1.0, abs(sin(length(uv) * 34.0 - time_f * 2.8 + hist * 9.0)));
    accum += acid(time_f * 0.04 + uv.x * 0.18) * halo * (0.08 + amp_smooth * 0.24);
    color = vec4(clamp(mix(accum, vec3(1.0) - accum, smoothstep(0.93, 1.0, amp_peak) * 0.10), 0.0, 1.0), 1.0);
}