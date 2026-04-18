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

    float tiles = 3.0 + 2.0 * aMid;
    vec2 uv = tc * tiles;
    vec2 cell = floor(uv);
    vec2 frac_ = fract(uv);

    frac_ = 1.0 - abs(1.0 - 2.0 * frac_);
    float cellAngle = (cell.x + cell.y) * 0.5 + t * 0.3;
    frac_ = rotateUV(frac_, cellAngle + aLow * 0.5, vec2(0.5), 1.0);

    for (int i = 0; i < 3; i++) {
        frac_ = abs(frac_ * 2.0 - 1.0);
    }
    frac_ = fract(frac_);

    vec4 tex = texture(samp, frac_);
    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = tex;
}
