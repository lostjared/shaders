#version 330 core
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float amp_peak;
uniform float amp_smooth;

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

vec2 mirror(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = tc * iResolution.xy;
    float cols = 3.0 + floor(aLow * 3.0);
    float rows = 2.0 + floor(aMid * 2.0);
    vec2 sectionSize = iResolution / vec2(cols, rows);
    vec2 idx = floor(uv / sectionSize);
    vec2 local = mod(uv, sectionSize) / sectionSize;
    float dir = mod(idx.x + idx.y, 2.0) * 2.0 - 1.0;
    float angle = dir * (t * (1.0 + aHigh) + length(idx) * 0.7);
    local = rot(angle) * (local - 0.5) + 0.5;
    local = mirror(local);
    vec2 texCoord = (idx + local) * sectionSize / iResolution.xy;
    color = texture(samp, texCoord);
    color.rgb *= 1.0 + amp_peak * 0.5;
}
