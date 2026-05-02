#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

float s3 = 1.7320508;

float hash12(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash22(vec2 p) {
    float n = sin(dot(p, vec2(269.5, 183.3)));
    return fract(vec2(262144.0, 32768.0) * n);
}

vec4 sampleRipple(vec2 uv) {
    float speedR = 5.0, amplitudeR = 0.03, wavelengthR = 10.0;
    float speedG = 6.5, amplitudeG = 0.025, wavelengthG = 12.0;
    float speedB = 4.0, amplitudeB = 0.035, wavelengthB = 8.0;

    float rR = sin(uv.x * wavelengthR + time_f * speedR) * amplitudeR;
    rR += sin(uv.y * wavelengthR * 0.8 + time_f * speedR * 1.2) * amplitudeR;
    vec2 uvR = uv + vec2(rR, rR);

    float rG = sin(uv.x * wavelengthG * 1.5 + time_f * speedG) * amplitudeG;
    rG += sin(uv.y * wavelengthG * 0.3 + time_f * speedG * 0.7) * amplitudeG;
    vec2 uvG = uv + vec2(rG, -rG * 0.5);

    float rB = sin(uv.x * wavelengthB * 0.5 + time_f * speedB) * amplitudeB;
    rB += sin(uv.y * wavelengthB * 1.7 + time_f * speedB * 1.3) * amplitudeB;
    vec2 uvB = uv + vec2(rB * 0.3, rB);

    vec4 c = texture(samp, uv);
    c.r = texture(samp, uvR).r;
    c.g = texture(samp, uvG).g;
    c.b = texture(samp, uvB).b;
    return c;
}

float sdHex(vec2 p, float r) {
    p = abs(p);
    return max(dot(p, vec2(0.8660254, 0.5)), p.y) - r;
}

vec4 compoundSample(vec2 uv) {
    float density = 22.0;
    vec2 g = vec2(density, density * 0.8660254);
    vec2 puv = uv * g;
    float row = floor(puv.y);
    float shift = mod(row, 2.0) * 0.5;
    float x = puv.x - shift;
    float col = floor(x);
    vec2 cell = vec2(col, row);

    vec2 bestC = cell;
    float bestD = 1e9;
    for (int j = -1; j <= 1; ++j) {
        for (int i = -1; i <= 1; ++i) {
            vec2 nb = cell + vec2(i, j);
            float sh = mod(nb.y, 2.0) * 0.5;
            vec2 center = vec2(nb.x + sh + 0.5, nb.y + 0.5);
            vec2 lp = vec2(puv.x, puv.y) - center;
            float d = dot(lp, lp);
            if (d < bestD) {
                bestD = d;
                bestC = nb;
            }
        }
    }

    float shBest = mod(bestC.y, 2.0) * 0.5;
    vec2 cCenter = vec2(bestC.x + shBest + 0.5, bestC.y + 0.5);
    vec2 lp = vec2(puv.x, puv.y) - cCenter;
    vec2 lpN = lp * 2.0;
    float edge = sdHex(lpN, 0.98);
    float seam = smoothstep(0.02, 0.0, 0.98 - abs(edge));
    float mask = 1.0 - smoothstep(0.0, 0.02, edge);

    vec2 cellId = bestC;
    vec2 jitter = (hash22(cellId) - 0.5) * 0.7;
    float tw = time_f * (1.0 + hash12(cellId) * 0.5);
    vec2 micro = normalize(vec2(cos(tw + jitter.x * 6.2831), sin(tw + jitter.y * 6.2831)));
    float r = clamp(1.0 - length(lp) * 2.0, 0.0, 1.0);
    float angleAmt = 0.02 + 0.02 * hash12(cellId + 3.7);
    vec2 baseOffset = micro * angleAmt * (0.15 + 0.85 * r * r);

    float disp = 0.003 + 0.004 * (1.0 - r);
    vec2 offR = baseOffset + vec2(disp, 0.0);
    vec2 offG = baseOffset;
    vec2 offB = baseOffset + vec2(-disp, 0.0);

    vec2 back = (cCenter + lp) / g;
    vec2 uvR = clamp(back + offR, 0.0, 1.0);
    vec2 uvG = clamp(back + offG, 0.0, 1.0);
    vec2 uvB = clamp(back + offB, 0.0, 1.0);

    vec3 c;
    vec4 sr = sampleRipple(uvR);
    vec4 sg = sampleRipple(uvG);
    vec4 sb = sampleRipple(uvB);
    c = vec3(sr.r, sg.g, sb.b);

    float theta = atan(lp.y, lp.x);
    float pol = 0.08 * (0.5 + 0.5 * cos(2.0 * theta + time_f * 1.7 + hash12(cellId) * 6.2831));
    c *= (1.0 + pol * r);

    float rim = smoothstep(0.0, 0.02, edge + 0.02);
    c *= mix(1.0, 0.15, rim);

    float grain = hash12(cellId + floor(time_f * 10.0)) * 0.06;
    c += (grain - 0.03) * r;

    return vec4(c, mask * (1.0 - rim) * seam);
}

void main() {
    vec4 cs = compoundSample(tc);
    vec3 base = sampleRipple(tc).rgb;
    vec3 outc = mix(base * 0.2, cs.rgb, cs.a);
    float v = smoothstep(1.0, 0.7, length(tc - 0.5));
    outc *= v;
    color = vec4(outc, 1.0);
}
