#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect) {
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 movingGradient(vec2 uv, vec2 c, float t, float aspect) {
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (uv - c) * ar;
    vec2 d = normalize(vec2(cos(t * 0.27), sin(t * 0.31)));
    float s = dot(p, d);
    float band = 0.5 + 0.5 * sin(s * 6.28318530718 * 0.35 + t * 0.9);
    float h = fract(s * 0.22 + t * 0.07 + 0.15 * sin(t * 0.33));
    float S = 0.75 + 0.25 * sin(t * 0.21 + s * 2.0);
    float V = 0.75 + 0.25 * band;
    vec3 base = hsv2rgb(vec3(h, S, V));
    float edge = smoothstep(0.2, 0.8, band);
    return mix(base * 0.6, base, edge);
}

mat2 rot2(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void juliaEval(vec2 z0, vec2 cJ, out float iterCount, out float smoothIter, out float orbitTrapVal) {
    vec2 z = z0;
    float i = 0.0;
    orbitTrapVal = 1e9;
    const int MAX_IT = 120;
    for (int k = 0; k < MAX_IT; k++) {
        orbitTrapVal = min(orbitTrapVal, length(z));
        vec2 z2 = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + cJ;
        z = z2;
        i += 1.0;
        if (dot(z, z) > 256.0)
            break;
    }
    float rl = length(z);
    smoothIter = i - log2(max(0.000001, log(max(rl, 1e-6))));
    iterCount = i;
}

float juliaScore(vec2 z0, vec2 cJ) {
    vec2 z = z0;
    const int MAX_S = 28;
    float i = 0.0;
    for (int k = 0; k < MAX_S; k++) {
        vec2 z2 = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + cJ;
        z = z2;
        i += 1.0;
        if (dot(z, z) > 256.0)
            break;
    }
    float rl = length(z);
    float sI = i - log2(max(0.000001, log(max(rl, 1e-6))));
    float tgt = 18.0;
    float score = 1.0 / (1.0 + abs(sI - tgt));
    return score;
}

vec2 findAnchor(vec2 base, vec2 cJ, float rad) {
    float best = -1.0;
    vec2 bestOff = vec2(0.0);
    for (int k = 0; k < 8; k++) {
        float a = (6.28318530718 / 8.0) * float(k) + time_f * 0.11;
        vec2 off = vec2(cos(a), sin(a)) * rad;
        float s = juliaScore(base + off, cJ);
        if (s > best) {
            best = s;
            bestOff = off;
        }
    }
    return bestOff;
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 uv = tc;
    vec4 originalTexture = texture(samp, tc);

    float t = time_f;
    float zoomSpeed = 0.28;
    float spin = 0.23;
    float scale = exp(-t * zoomSpeed);
    vec2 p = (uv - m) * ar;
    p = rot2(t * spin) * p;

    vec2 cJ = (iMouse.z > 0.5)
                  ? ((iMouse.xy / iResolution) * 2.0 - 1.0) * vec2(aspect, 1.0) * 0.6
                  : vec2(0.285 + 0.15 * sin(t * 0.17), 0.01 + 0.15 * cos(t * 0.21));

    float probeRad = 0.75 * scale;
    vec2 anchor = findAnchor(vec2(0.0), cJ, probeRad);
    vec2 z0 = (p + anchor) * scale * 2.0;

    float iterCount, smoothIter, orbitTrapVal;
    juliaEval(z0, cJ, iterCount, smoothIter, orbitTrapVal);

    float rD = length(p);
    float hue = fract(0.12 * smoothIter + 0.07 * t + 0.15 * sin(orbitTrapVal * 3.0));
    float sat = 0.65 + 0.25 * sin(0.7 * t + orbitTrapVal * 5.0);
    float val = 0.80 + 0.20 * sin(0.9 * t + smoothIter * 0.35);
    vec3 tint = hsv2rgb(vec3(hue, sat, val));

    float ring = smoothstep(0.0, 0.7, sin(log(rD * scale + 1e-3) * 9.5 + t * 1.2));
    float pulse = 0.5 + 0.5 * sin(t * 2.0 + rD * 28.0 + smoothIter * 0.6);

    float vign = 1.0 - smoothstep(0.75, 1.2, length((tc - m) * ar));
    vign = mix(0.85, 1.2, vign);

    vec2 pr = z0;
    vec2 dir = normalize(pr + 1e-6);
    vec2 off = dir * (0.0015 + 0.001 * sin(t * 1.3)) * vec2(1.0, 1.0 / aspect);

    vec2 u0 = fract(pr / ar + m);
    vec2 u1 = fract((pr * 1.045) / ar + m);
    vec2 u2 = fract((pr * 0.955) / ar + m);

    float rC = texture(samp, u0 + off).r;
    float gC = texture(samp, u1).g;
    float bC = texture(samp, u2 - off).b;
    vec3 texRGB = vec3(rC, gC, bC);

    float shade = smoothstep(0.0, 1.0, 1.0 - clamp(orbitTrapVal * 0.5, 0.0, 1.0));
    vec3 fractRGB = mix(texRGB, texRGB * tint, 0.65) * mix(0.7, 1.25, shade);
    vec4 fractalColor = vec4(fractRGB * tint, 1.0);

    float blendFactor = 0.58;
    vec4 merged = mix(fractalColor, originalTexture, blendFactor);
    merged.rgb *= (0.75 + 0.25 * ring) * (0.85 + 0.15 * pulse) * vign;

    vec3 bloom = merged.rgb * merged.rgb * 0.18 + pow(max(merged.rgb - 0.6, 0.0), vec3(2.0)) * 0.12;
    vec3 outCol = merged.rgb + bloom;

    float wob = 0.9 + 0.1 * sin(t + rD * 14.0 + smoothIter * 0.5);
    outCol *= wob;

    vec3 grad = movingGradient(tc, m, t, aspect);
    float gradAmt = 0.35 + 0.25 * sin(t * 0.5 + rD * 7.0 + smoothIter * 0.35);
    vec3 screenBlend = 1.0 - (1.0 - outCol) * (1.0 - grad);
    outCol = mix(outCol, screenBlend, gradAmt);

    vec4 tcol = texture(samp, tc);
    outCol = mix(outCol, outCol * tcol.rgb, 0.8);

    outCol = sin(outCol * (0.5 + 0.5 * pingPong(t, 12.0)));
    outCol = clamp(outCol, vec3(0.08), vec3(0.96));

    color = vec4(outCol, 1.0);
}
