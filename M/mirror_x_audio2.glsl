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
    float aHigh = clamp(amp_high, 0.0, 1.0);
    vec2 uv = tc * iResolution.xy;
    float tileSize = mix(80.0, 200.0, aLow);
    vec2 idx = floor(uv / tileSize);
    vec2 local = mod(uv, tileSize) / tileSize;
    float angle = time_f * (1.0 + aHigh * 2.0) + length(idx) * 0.5;
    local = rot(angle) * (local - 0.5) + 0.5;
    local = mirror(local);
    vec2 texCoord = (idx + local) * tileSize / iResolution.xy;
    color = texture(samp, texCoord);
    color.rgb *= 1.0 + amp_peak * 0.4;
}
