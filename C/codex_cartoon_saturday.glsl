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

float luma(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec3 sampleClamp(vec2 uv) {
    return texture(samp, clamp(uv, vec2(0.0), vec2(1.0))).rgb;
}

vec3 saturdayPalette(float t) {
    vec3 p0 = vec3(0.98, 0.88, 0.38);
    vec3 p1 = vec3(0.98, 0.55, 0.22);
    vec3 p2 = vec3(0.98, 0.30, 0.35);
    vec3 p3 = vec3(0.46, 0.78, 0.95);
    vec3 p4 = vec3(0.30, 0.88, 0.62);
    vec3 p5 = vec3(0.98, 0.95, 0.82);

    if (t < 0.20) return mix(p0, p1, t / 0.20);
    if (t < 0.40) return mix(p1, p2, (t - 0.20) / 0.20);
    if (t < 0.60) return mix(p2, p3, (t - 0.40) / 0.20);
    if (t < 0.80) return mix(p3, p4, (t - 0.60) / 0.20);
    return mix(p4, p5, (t - 0.80) / 0.20);
}

void main(void)
{
    vec2 res = max(iResolution, vec2(1.0));
    vec2 px = 1.0 / res;

    vec2 uv = tc;
    vec2 p = uv * 2.0 - 1.0;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / res) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= res.x / res.y;
    float mouseGlow = smoothstep(1.35, 0.0, length(p - mouseP));

    p += vec2(sin((p.y + time_f * 0.2) * 8.0), cos((p.x - time_f * 0.15) * 7.0)) * 0.0025;
    p.x += p.x * p.x * 0.02;
    p.y += p.y * p.y * 0.01;
    p += (mouseP - p) * 0.04 * mouseGlow;

    uv = p * 0.5 + 0.5;
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        color = vec4(0.98, 0.96, 0.90, 1.0);
        return;
    }

    vec3 c = sampleClamp(uv);
    vec3 blur = c * 4.0;
    blur += sampleClamp(uv + vec2( px.x,  0.0));
    blur += sampleClamp(uv + vec2(-px.x,  0.0));
    blur += sampleClamp(uv + vec2( 0.0,  px.y));
    blur += sampleClamp(uv + vec2( 0.0, -px.y));
    blur *= 0.125;

    float lum = luma(blur);
    float tone = floor(clamp(lum, 0.0, 1.0) * 5.0 + 0.5) / 5.0;
    vec3 pal = saturdayPalette(tone);

    float sat = max(max(blur.r, blur.g), blur.b) - min(min(blur.r, blur.g), blur.b);
    vec3 toon = mix(vec3(lum), pal, 0.75 + sat * 0.55);
    toon = mix(toon, blur, 0.08);
    toon += mouseGlow * vec3(0.07, 0.04, 0.03);

    float tl = luma(sampleClamp(clamp(uv + px * vec2(-1.0, -1.0), vec2(0.0), vec2(1.0))));
    float t  = luma(sampleClamp(clamp(uv + px * vec2( 0.0, -1.0), vec2(0.0), vec2(1.0))));
    float tr = luma(sampleClamp(clamp(uv + px * vec2( 1.0, -1.0), vec2(0.0), vec2(1.0))));
    float l  = luma(sampleClamp(clamp(uv + px * vec2(-1.0,  0.0), vec2(0.0), vec2(1.0))));
    float r  = luma(sampleClamp(clamp(uv + px * vec2( 1.0,  0.0), vec2(0.0), vec2(1.0))));
    float bl = luma(sampleClamp(clamp(uv + px * vec2(-1.0,  1.0), vec2(0.0), vec2(1.0))));
    float b  = luma(sampleClamp(clamp(uv + px * vec2( 0.0,  1.0), vec2(0.0), vec2(1.0))));
    float br = luma(sampleClamp(clamp(uv + px * vec2( 1.0,  1.0), vec2(0.0), vec2(1.0))));
    float gx = -tl - 2.0 * l - bl + tr + 2.0 * r + br;
    float gy = -tl - 2.0 * t - tr + bl + 2.0 * b + br;
    float edge = smoothstep(0.10, 0.34, length(vec2(gx, gy)));

    float shade = smoothstep(0.12, 0.82, lum);
    float bands = floor(shade * 4.0 + 0.5) / 4.0;
    toon *= mix(0.70, 1.08, bands);

    float highlight = smoothstep(0.62, 0.92, lum);
    toon += highlight * vec3(0.08, 0.05, 0.03);
    toon += (hash(floor(gl_FragCoord.xy) + floor(time_f * 24.0)) - 0.5) * 0.018;

    vec3 line = vec3(0.04, 0.03, 0.06);
    toon = mix(toon, line, edge * 0.88);

    float paper = 1.0 - (hash(floor(gl_FragCoord.xy * 0.75)) - 0.5) * 0.04;
    toon *= paper;
    toon = pow(clamp(toon, 0.0, 1.0), vec3(0.95));
    toon = mix(toon, toon * vec3(1.03, 1.01, 0.98), 0.18);

    color = vec4(clamp(toon, 0.0, 1.0), 1.0);
}
