#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;
const float PI = 3.1415926535897932384626433832795;

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
    for (int i = 0; i < 4; i++) { // Reduced iterations slightly for clarity on the sphere surface
        p = abs((p - c) * (zoom + 0.1 * sin(t * 0.3 + float(i)))) - 0.4 + c;
        p = rotateUV(p, t * 0.1 + float(i) * 0.05, c, aspect);
    }
    return p;
}

vec3 neonPalette(float t) {
    vec3 pink = vec3(1.0, 0.2, 0.8);
    vec3 cyan = vec3(0.0, 0.9, 1.0);
    vec3 purple = vec3(0.6, 0.1, 1.0);
    float ph = fract(t * 0.1);
    if (ph < 0.33)
        return mix(pink, cyan, ph * 3.0);
    if (ph < 0.66)
        return mix(cyan, purple, (ph - 0.33) * 3.0);
    return mix(purple, pink, (ph - 0.66) * 3.0);
}

vec3 softTone(vec3 c) {
    return pow(clamp(c, 0.0, 1.0), vec3(0.85));
}

vec3 preBlendColor(vec2 uv) {
    vec3 tex = texture(samp, uv).rgb;
    float brightness = dot(tex, vec3(0.299, 0.587, 0.114));
    vec3 neon = neonPalette(time_f + brightness);
    // Strobing pulse logic
    float strobe = 0.9 + 0.1 * sin(time_f * 20.0);
    return mix(tex, neon, 0.5) * strobe;
}

float diamondRadius(vec2 p) {
    p = abs(p);
    return max(p.x, p.y);
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
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    // 1. Create Spherical / Fisheye coordinates
    vec2 p_centered = (tc - 0.5) * 2.0;
    p_centered.x *= aspect;
    float d = length(p_centered);

    // Spherical bulging effect
    float sphereRadius = 1.0;
    float z = sqrt(max(0.0, sphereRadius * sphereRadius - d * d));
    float fisheye = atan(d, z) / (PI * 0.5);

    // Create the "Sphere UVs"
    vec2 sphereUV = (d > 0.0) ? (p_centered / d) * fisheye : vec2(0.0);
    sphereUV.x /= aspect;
    sphereUV = sphereUV * 0.5 + 0.5; // Back to 0-1 range

    // 2. Base Texture and Alpha
    vec4 baseTex = texture(samp, tc);

    // 3. Aura Masking (The boundary of the sphere)
    float mask = smoothstep(1.0, 0.95, d);           // Harder edge for the sphere
    float outerGlow = smoothstep(1.3, 0.0, d) * 0.4; // Soft light around the ball

    // 4. Kaleidoscope Logic applied to Sphere UVs
    float seg = 6.0 + 2.0 * sin(time_f * 0.5);
    vec2 kUV = reflectUV(sphereUV, seg, m, aspect);
    kUV = diamondFold(kUV, m, aspect);

    float foldZoom = 1.2 + 0.3 * sin(time_f * 0.4);
    kUV = fractalFold(kUV, foldZoom, time_f, m, aspect);

    // 5. Texture mapping within the sphere
    vec2 p = (kUV - m) * vec2(aspect, 1.0);
    float rD = diamondRadius(p) + 1e-6;
    float ang = atan(p.y, p.x) + time_f * 0.3;
    float k = fract(log(rD) - time_f * 0.5);
    vec2 pwrap = vec2(cos(ang), sin(ang)) * exp(k);

    vec2 u0 = fract(pwrap + m);
    vec3 kaleidoRGB = preBlendColor(u0);

    // 6. Lighting / Shading the sphere
    float shading = dot(normalize(vec3(p_centered, z)), normalize(vec3(1.0, 1.0, 1.0)));
    shading = smoothstep(-0.2, 1.0, shading);

    // 7. Final Mix
    vec3 sphereCol = kaleidoRGB * shading * 1.5;
    sphereCol += pow(shading, 10.0) * 0.5; // Specular highlight

    // Combine Kaleidoscope with Base Background
    vec3 finalRGB = mix(baseTex.rgb * 0.5, sphereCol, mask);
    finalRGB += neonPalette(time_f * 0.5) * outerGlow * (0.5 + 0.5 * sin(time_f * 5.0)); // Strobing Aura

    color = vec4(finalRGB, 1.0);
}