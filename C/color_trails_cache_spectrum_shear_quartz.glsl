#version 330 core
// Faceted shear trails with crystalline slipping motion.
in vec2 tc;
out vec4 color;
uniform sampler2D samp, samp1, samp2, samp3, samp4, samp5, samp6, samp7, samp8;
uniform sampler1D spectrum0, spectrum1, spectrum2, spectrum3, spectrum4, spectrum5, spectrum6, spectrum7;
uniform float time_f, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float TAU = 6.28318530718;
vec3 acid(float t) { return 0.5 + 0.5 * cos(TAU * (vec3(0.78, 0.92, 1.0) * t + vec3(0.03, 0.21, 0.47))); }
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
vec2 shearField(vec2 uv, float bass, float mid, float treble, float air, vec3 oldest, float layer) {
    vec2 dir = vec2(uv.y * 0.65 + sin(uv.x * 10.0 + time_f * 1.1 + layer), uv.x * -0.35 + cos(uv.y * 14.0 - time_f * 1.8 - layer));
    dir += vec2(oldest.r - oldest.b, oldest.g - 0.5);
    return dir * (0.014 + mid * 0.030 + air * 0.016) + vec2(bass * 0.02, -treble * 0.015);
}
void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float bass = texture(spectrum0, 0.03).r, mid = texture(spectrum0, 0.19).r, treble = texture(spectrum0, 0.57).r, air = texture(spectrum0, 0.87).r;
    float hist = 0.0;
    for (int i = 0; i < 8; i++)
        hist += specHist(i, 0.19);
    hist /= 8.0;
    vec3 oldest = texture(samp8, tc + vec2(cos(time_f * 0.20 + uv.y * 8.0), sin(time_f * 0.22 + uv.x * 8.5)) * (0.012 + hist * 0.028)).rgb;
    vec3 live = texture(samp, tc + shearField(uv, bass, mid, treble, air, oldest, 0.0)).rgb * acid(time_f * 0.06 + uv.x * 0.4 + mid);
    vec3 accum = live;
    float wsum = 1.0;
    for (int i = 0; i < 8; i++) {
        float layer = float(i + 1);
        float hB = specHist(i, 0.03), hM = specHist(i, 0.19), hT = specHist(i, 0.57), hA = specHist(i, 0.87);
        vec3 cached = cacheHist(i, tc + shearField(uv, hB, hM, hT, hA, oldest, layer)).rgb;
        float w = pow(0.80, layer) * (1.0 + hM * 1.2 + hA * 0.5);
        accum += cached * acid(layer * 0.10 + hT * 0.6) * w;
        wsum += w;
    }
    accum /= wsum;
    float edge = smoothstep(0.35, 1.0, abs(sin((uv.x - uv.y) * 18.0 + time_f * 2.2 + hist * 8.0)));
    accum += acid(time_f * 0.03 + uv.y * 0.3) * edge * (0.07 + amp_smooth * 0.18);
    color = vec4(clamp(accum, 0.0, 1.0), 1.0);
}