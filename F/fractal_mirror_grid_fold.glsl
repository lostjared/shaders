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

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect) {
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;
    vec2 ctr = vec2(0.5);

    float gridSize = 4.0 + 3.0 * aMid;
    vec2 uv = tc * gridSize;
    vec2 cell = floor(uv);
    vec2 frac_ = fract(uv);

    frac_ = 1.0 - abs(1.0 - 2.0 * frac_);

    float cellPhase = (cell.x * 7.0 + cell.y * 13.0) * 0.1;
    frac_ = rotateUV(frac_, t * 0.2 + cellPhase + aLow * 0.5, vec2(0.5), 1.0);

    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        frac_ = abs((frac_ - 0.5) * (1.3 + 0.1 * aLow * sin(t * 0.5 + fi))) + 0.5;
    }
    frac_ = 1.0 - abs(1.0 - 2.0 * fract(frac_));

    vec4 tex = texture(samp, frac_);
    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = tex;
}
