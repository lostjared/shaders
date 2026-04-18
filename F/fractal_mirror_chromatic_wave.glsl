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
uniform float amp_rms;

vec2 mirror(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;

    vec2 uv = tc;
    uv.x += sin(uv.y * 15.0 + t * 3.0) * 0.03 * aMid;
    uv.y += cos(uv.x * 12.0 + t * 2.5) * 0.03 * aHigh;
    uv = mirror(uv);

    float chromaStr = 0.005 + 0.01 * aPk + 0.005 * aHigh;
    vec2 dir = normalize(uv - 0.5 + 1e-5);
    vec2 off = dir * chromaStr;

    vec3 rC = texture(samp, fract(uv + off)).rgb;
    vec3 gC = texture(samp, fract(uv)).rgb;
    vec3 bC = texture(samp, fract(uv - off)).rgb;
    vec3 col = vec3(rC.r, gC.g, bC.b);

    col *= 1.0 + aPk * 0.6;
    col = mix(col, col * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
