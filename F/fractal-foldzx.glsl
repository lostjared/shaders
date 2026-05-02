#version 330 core
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float time_f;
uniform float amp;
uniform float uamp;

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect) {
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

vec2 reflectUV(vec2 uv, float segments, vec2 c, float aspect) {
    vec2 p = uv - c;
    p.x *= aspect;
    float ang = atan(p.y, p.x);
    float rad = length(p);
    float stepA = 6.28318530718 / segments;
    ang = mod(ang, stepA);
    ang = abs(ang - stepA * 0.5);
    vec2 r = vec2(cos(ang), sin(ang)) * rad;
    r.x /= aspect;
    return r + c;
}

vec2 fractalFold(vec2 uv, float zoom, float t, vec2 c, float aspect) {
    vec2 p = uv;
    for (int i = 0; i < 4; i++) { // Increase the number of folds for more complex patterns
        p = abs((p - c) * (zoom + 0.10 * sin(t * 0.35 + float(i)))) - 0.5 + c;
        if (i % 2 == 0) { // Alternate between rotation and scaling for more chaos
            p = rotateUV(p, t * 0.12 + float(i) * 0.07, c, aspect);
        } else {
            float scaleFactor = 1.0 + sin(t * 0.15 + float(i)) * 0.3; // Adding some scaling variation
            p *= scaleFactor;
        }
    }
    return p;
}

vec2 diamondFold(vec2 uv, vec2 c, float aspect) {
    vec2 p = (uv - c) * vec2(aspect, 1.0);
    p = abs(p);
    if (p.y > p.x)
        p = p.yx;
    p.x /= aspect;
    return p + c;
}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = tc;
    float A = clamp(amp, 0.0, 1.0);
    float U = clamp(uamp, 0.0, 1.0);
    vec2 m = (iMouse.z > 0.5 || iMouse.w > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 normPos = (uv - m) * vec2(aspect, 1.0);
    float dist = length(normPos);
    float phase = sin(dist * 8.0 - time_f * 2.0);
    float rippleStrength = 0.02 + (0.05 * A);
    vec2 rippledUV = uv + (normPos * phase * rippleStrength);
    float seg = 4.0 + 2.0 * sin(time_f * 0.1);
    vec2 kUV = reflectUV(rippledUV, seg, m, aspect);
    kUV = diamondFold(kUV, m, aspect);
    float foldZoom = 1.05 + 0.1 * sin(time_f * 0.2);
    kUV = fractalFold(kUV, foldZoom, time_f, m, aspect);
    vec2 mapUV = (kUV - m) * vec2(aspect, 1.0);
    mapUV *= 0.8;
    float rot = time_f * 0.1;
    float s = sin(rot);
    float c = cos(rot);
    mapUV = mat2(c, -s, s, c) * mapUV;
    float dispersion = 0.01 + (U * 0.05);
    vec2 dispOffset = normalize(mapUV) * dispersion * length(mapUV);
    vec2 centerBase = mapUV + m;
    vec2 uvR = centerBase - dispOffset;
    vec2 uvG = centerBase;
    vec2 uvB = centerBase + dispOffset;
    vec2 texR = abs(mod(uvR - 1.0, 2.0) - 1.0);
    vec2 texG = abs(mod(uvG - 1.0, 2.0) - 1.0);
    vec2 texB = abs(mod(uvB - 1.0, 2.0) - 1.0);
    float r = texture(samp, texR).r;
    float g = texture(samp, texG).g;
    float b = texture(samp, texB).b;
    float light = 1.0 + 0.5 * sin(dist * 20.0 - time_f * 5.0);
    vec3 finalCol = vec3(r, g, b) * light;
    float vign = 1.0 - smoothstep(0.5, 1.5, dist);
    finalCol *= vign;
    color = vec4(finalCol, 1.0);
}
