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
    return 1.0 - abs(1.0 - 2.0 * uv);
}

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

    vec2 uv = tc;
    vec2 p = (uv - ctr) * vec2(aspect, 1.0);
    float rad = length(p);
    float ang = atan(p.y, p.x);

    float hexSeg = 6.0;
    float segAngle = 6.28318 / hexSeg;
    ang = mod(ang + segAngle * 0.5, segAngle) - segAngle * 0.5;
    ang = abs(ang);

    vec2 hexUV = vec2(cos(ang), sin(ang)) * rad;
    hexUV.x /= aspect;
    hexUV += ctr;

    float zoom = 1.3 + 0.3 * aLow;
    for (int i = 0; i < 4; i++) {
        hexUV = abs((hexUV - ctr) * zoom) + ctr - 0.5;
        hexUV = rotateUV(hexUV, t * 0.1 + float(i) * 0.15, ctr, aspect);
    }
    hexUV = mirror(fract(hexUV));

    vec4 tex = texture(samp, hexUV);
    float ring = abs(sin(rad * 20.0 - t * 2.0 * (1.0 + aLow)));
    ring = smoothstep(0.8, 1.0, ring) * 0.2 * aHigh;
    tex.rgb += ring;

    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
