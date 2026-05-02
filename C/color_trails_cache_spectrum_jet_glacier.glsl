#version 330 core
// Cold glacial jets with heavy smooth drag and blue-white wakes.
in vec2 tc;
out vec4 color;
uniform sampler2D samp, samp1, samp2, samp3, samp4, samp5, samp6, samp7, samp8;
uniform sampler1D spectrum0, spectrum1, spectrum2, spectrum3, spectrum4, spectrum5, spectrum6, spectrum7;
uniform float time_f, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float TAU = 6.28318530718;
vec3 acid(float t) { return 0.5 + 0.5 * cos(TAU * (vec3(0.55, 0.78, 1.0) * t + vec3(0.16, 0.32, 0.46))); }
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
vec2 jetField(vec2 uv, float bass, float mid, float treble, float air, vec3 oldest, float layer) {
    vec2 dir = normalize(vec2(-0.6 + 0.3 * cos(time_f * 0.8 + layer), 1.0 + 0.2 * sin(uv.x * 6.0)) + 0.0001);
    dir += vec2(oldest.g - oldest.r, oldest.b - oldest.g) * 0.6;
    return dir * (0.010 + mid * 0.024 + air * 0.022) - uv * (0.002 + bass * 0.010);
}
void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float bass = texture(spectrum0, 0.03).r, mid = texture(spectrum0, 0.24).r, treble = texture(spectrum0, 0.52).r, air = texture(spectrum0, 0.88).r;
    float hist = 0.0;
    for (int i = 0; i < 8; i++)
        hist += specHist(i, 0.24);
    hist /= 8.0;
    vec3 oldest = texture(samp8, tc + vec2(cos(time_f * 0.13 + uv.y * 5.0), sin(time_f * 0.15 + uv.x * 5.0)) * (0.010 + hist * 0.026)).rgb;
    vec3 live = texture(samp, tc + jetField(uv, bass, mid, treble, air, oldest, 0.0)).rgb * acid(time_f * 0.04 + uv.y * 0.16 + air);
    vec3 accum = live;
    float wsum = 1.0;
    for (int i = 0; i < 8; i++) {
        float layer = float(i + 1);
        float hB = specHist(i, 0.03), hM = specHist(i, 0.24), hT = specHist(i, 0.52), hA = specHist(i, 0.88);
        vec3 cached = cacheHist(i, tc + jetField(uv, hB, hM, hT, hA, oldest, layer)).rgb;
        float w = pow(0.83, layer) * (1.0 + hM * 1.0 + hA * 0.6);
        accum += cached * acid(layer * 0.08 + hA * 0.7) * w;
        wsum += w;
    }
    accum /= wsum;
    float frost = smoothstep(0.45, 1.0, abs(cos((uv.x - uv.y) * 18.0 - time_f * 1.7 + hist * 7.0)));
    accum += vec3(0.8, 0.95, 1.0) * frost * (0.04 + amp_smooth * 0.15);
    color = vec4(clamp(accum, 0.0, 1.0), 1.0);
}