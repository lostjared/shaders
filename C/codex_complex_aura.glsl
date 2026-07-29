#version 330 core
in vec2 tc;
out vec4 color;
uniform float alpha_r;
uniform float alpha_g;
uniform float alpha_b;
uniform float alpha;
uniform vec4 optx;
uniform vec4 random_var;
uniform float alpha_value;
uniform mat4 mv_matrix;
uniform mat4 proj_matrix;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float value_alpha_r, value_alpha_g, value_alpha_b;
uniform float index_value;
uniform float time_f;
uniform vec2 iResolution;

uniform float restore_black;
uniform vec4 inc_valuex;
uniform vec4 inc_value;
uniform vec2 image_pos;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

vec2 mirrorWrap(vec2 p) {
    return abs(fract(p) * 2.0 - 1.0);
}

vec2 kalei(vec2 p, float segments) {
    float ang = atan(p.y, p.x);
    float rad = length(p);
    float stepAng = 6.28318530718 / segments;
    ang = mod(ang + stepAng * 0.5, stepAng);
    ang = abs(ang - stepAng * 0.5);
    return vec2(cos(ang), sin(ang)) * rad;
}

vec3 palette(float t) {
    vec3 a = vec3(0.28, 0.62, 0.98);
    vec3 b = vec3(0.62, 0.30, 1.00);
    vec3 c = vec3(0.98, 0.45, 0.84);
    vec3 d = vec3(0.95, 0.85, 1.00);
    float x = fract(t);
    if (x < 0.33) return mix(a, b, x / 0.33);
    if (x < 0.66) return mix(b, c, (x - 0.33) / 0.33);
    return mix(c, d, (x - 0.66) / 0.34);
}

void main(void)
{
    vec2 res = max(iResolution, vec2(1.0));
    float aspect = res.x / max(res.y, 1.0);
    float t = time_f * 0.32;

    vec2 p = tc - 0.5;
    p.x *= aspect;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / res) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= aspect;

    float pulse = 0.5 + 0.5 * sin(time_f * 1.4);
    float breathe = 0.78 + 0.24 * sin(time_f * 0.72 + pulse * 3.14159);
    float ringScale = mix(0.8, 1.55, breathe);

    vec2 z = (p - mouseP * 0.35) * ringScale;
    z = kalei(z, 6.0 + 2.0 * pulse);
    z.x = abs(z.x);
    z.y = abs(z.y);

    vec2 sampleUV = mirrorWrap(tc * 1.4 + vec2(0.03 * sin(t), 0.03 * cos(t * 1.3)));
    vec3 src = texture(samp, sampleUV).rgb;

    float trap = 1e9;
    float orbit = 0.0;
    vec2 q = z;
    for (int i = 0; i < 12; ++i) {
        q = abs(q) / max(dot(q, q), 0.16);
        q = rot(0.32 + 0.09 * sin(t + float(i))) * q;
        q -= vec2(0.74 + 0.08 * sin(t * 1.7), 0.46 + 0.05 * cos(t * 1.3));
        q = abs(q);
        float d = length(q);
        trap = min(trap, d);
        orbit += exp(-d * (1.2 + 0.18 * float(i)));
    }

    float core = exp(-trap * 2.4);
    float shell = exp(-abs(trap - (0.18 + 0.08 * sin(time_f * 1.9))) * 14.0);
    float halo = exp(-length(z) * (3.0 - 0.7 * pulse));
    float aura = clamp(core * 1.05 + shell * 0.75 + halo * 0.55 + orbit * 0.03, 0.0, 1.0);

    vec2 warp = z;
    warp *= rot(0.4 * sin(time_f * 0.6));
    warp += vec2(sin(warp.y * 6.0 + time_f * 2.2), cos(warp.x * 7.0 - time_f * 1.7)) * 0.03 * aura;
    warp += (mouseP - p) * 0.08 * aura;
    vec2 texUV = mirrorWrap(tc + warp * 0.055);

    vec3 tex = texture(samp, texUV).rgb;
    vec3 tint = palette(aura * 1.7 + time_f * 0.05 + trap * 0.8);

    vec3 glow = tex * (0.4 + aura * 0.6);
    glow += tint * (0.35 + aura * 0.9);
    glow += src * 0.18;
    glow += palette(trap * 4.0 + time_f * 0.2) * shell * 0.8;

    float vignette = smoothstep(1.35, 0.15, length(p - mouseP * 0.18));
    float shimmer = 0.88 + 0.12 * sin((p.y * 32.0 + time_f * 5.0) + sin(p.x * 9.0 + time_f));
    glow *= vignette * shimmer;

    float alphaOut = clamp(aura * 0.92 + core * 0.22 + shell * 0.10, 0.0, 1.0);
    alphaOut *= alpha;
    alphaOut *= 0.55 + 0.45 * vignette;

    vec3 colorOut = mix(src * 0.15, glow, aura);
    colorOut = mix(colorOut, tint * 1.2, shell * 0.55);
    colorOut += vec3(0.03, 0.02, 0.06) * halo * 0.35;
    colorOut = clamp(colorOut, 0.0, 1.0);

    color = vec4(colorOut, alphaOut);
}
