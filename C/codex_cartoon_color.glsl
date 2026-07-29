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

vec3 palette(float t) {
    vec3 c1 = vec3(0.98, 0.78, 0.34);
    vec3 c2 = vec3(0.96, 0.35, 0.28);
    vec3 c3 = vec3(0.20, 0.62, 0.92);
    vec3 c4 = vec3(0.98, 0.92, 0.74);
    if (t < 0.33) {
        return mix(c1, c2, t / 0.33);
    }
    if (t < 0.66) {
        return mix(c2, c3, (t - 0.33) / 0.33);
    }
    return mix(c3, c4, (t - 0.66) / 0.34);
}

void main(void)
{
    vec2 res = max(iResolution, vec2(1.0));
    vec2 px = 1.0 / res;
    vec4 src = texture(samp, tc);
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / res) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= res.x / res.y;
    float mouseOrbit = smoothstep(0.9, 0.0, length((tc * 2.0 - 1.0) * vec2(res.x / res.y, 1.0) - mouseP));

    vec3 blur = src.rgb * 4.0;
    blur += sampleClamp(tc + vec2( px.x,  0.0));
    blur += sampleClamp(tc + vec2(-px.x,  0.0));
    blur += sampleClamp(tc + vec2( 0.0,  px.y));
    blur += sampleClamp(tc + vec2( 0.0, -px.y));
    blur *= 0.125;

    float lum = luma(blur);
    float tone = floor(clamp(lum, 0.0, 1.0) * 4.0 + 0.5) / 4.0;
    vec3 toon = palette(tone);

    float chroma = max(max(blur.r, blur.g), blur.b) - min(min(blur.r, blur.g), blur.b);
    toon = mix(vec3(lum), toon, 0.55 + chroma * 0.85);
    toon = mix(toon, blur, 0.12);
    toon = mix(toon, palette(tone + mouseOrbit * 0.55), mouseOrbit * 0.28);

    float tl = luma(sampleClamp(tc + px * vec2(-1.0, -1.0)));
    float t  = luma(sampleClamp(tc + px * vec2( 0.0, -1.0)));
    float tr = luma(sampleClamp(tc + px * vec2( 1.0, -1.0)));
    float l  = luma(sampleClamp(tc + px * vec2(-1.0,  0.0)));
    float r  = luma(sampleClamp(tc + px * vec2( 1.0,  0.0)));
    float bl = luma(sampleClamp(tc + px * vec2(-1.0,  1.0)));
    float b  = luma(sampleClamp(tc + px * vec2( 0.0,  1.0)));
    float br = luma(sampleClamp(tc + px * vec2( 1.0,  1.0)));
    float gx = -tl - 2.0 * l - bl + tr + 2.0 * r + br;
    float gy = -tl - 2.0 * t - tr + bl + 2.0 * b + br;
    float edge = smoothstep(0.14, 0.42, length(vec2(gx, gy)));

    float band = smoothstep(0.15, 0.75, lum);
    float cel = mix(0.36, 1.15, band);
    toon *= cel;

    float dither = hash(floor(gl_FragCoord.xy * 0.5) + floor(time_f * 6.0)) - 0.5;
    toon += dither * 0.06;

    float halftone = 0.5 + 0.5 * sin((gl_FragCoord.x + gl_FragCoord.y * 1.3) * 0.55);
    float shadowInk = (1.0 - band) * step(0.35, halftone) * 0.09;
    toon -= shadowInk;
    toon += mouseOrbit * vec3(0.03, 0.02, 0.04);

    vec3 ink = vec3(0.03, 0.02, 0.03);
    toon = mix(toon, ink, edge * 0.95);
    toon = pow(clamp(toon, 0.0, 1.0), vec3(0.92));

    color = vec4(toon, src.a);
}
