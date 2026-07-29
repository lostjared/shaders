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

vec3 cartoonPalette(float t) {
    vec3 a = vec3(0.98, 0.79, 0.30);
    vec3 b = vec3(0.96, 0.43, 0.24);
    vec3 c = vec3(0.22, 0.65, 0.90);
    vec3 d = vec3(0.98, 0.92, 0.76);
    vec3 e = vec3(0.78, 0.33, 0.82);
    if (t < 0.25) return mix(a, b, t / 0.25);
    if (t < 0.50) return mix(b, c, (t - 0.25) / 0.25);
    if (t < 0.75) return mix(c, d, (t - 0.50) / 0.25);
    return mix(d, e, (t - 0.75) / 0.25);
}

void main(void)
{
    vec2 res = max(iResolution, vec2(1.0));
    vec2 px = 1.0 / res;

    vec2 uv = tc * 2.0 - 1.0;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / res) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= res.x / res.y;
    float mouseDist = length(uv - mouseP);

    float scanWave = sin((uv.y * 2.1 + time_f * 0.9) * 18.0);
    float bend = uv.x * uv.x * 0.065 + uv.y * uv.y * 0.035;
    uv.x += bend * sign(uv.x);
    uv.y += bend * 0.35;
    uv.x += sin(uv.y * 11.0 + time_f * 2.4) * 0.006;
    uv.y += sin(uv.x * 7.0 - time_f * 1.5) * 0.002;
    uv += (mouseP - uv) * 0.06 * smoothstep(1.45, 0.0, mouseDist);

    vec2 tape = uv * 0.5 + 0.5;
    float tear = step(0.972, hash(vec2(floor(time_f * 12.0), floor(tape.y * 180.0)))) * (hash(vec2(tape.y, time_f)) - 0.5);
    tear += smoothstep(0.55, 0.0, mouseDist) * 0.35;
    tape.x += tear * 0.05;
    tape.x += (hash(vec2(floor(time_f * 30.0), floor(tape.y * 240.0))) - 0.5) * 0.0035;
    tape.y += sin(tape.x * 180.0 + time_f * 15.0) * 0.0008;

    if (tape.x < 0.0 || tape.x > 1.0 || tape.y < 0.0 || tape.y > 1.0) {
        color = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec2 chromaShift = vec2(0.0035 + 0.0015 * sin(time_f * 2.0), 0.0);
    float focus = 1.0 - smoothstep(0.42, 0.92, length(tc - 0.5));

    vec3 base;
    base.r = texture(samp, clamp(tape + chromaShift, vec2(0.0), vec2(1.0))).r;
    base.g = texture(samp, clamp(tape, vec2(0.0), vec2(1.0))).g;
    base.b = texture(samp, clamp(tape - chromaShift, vec2(0.0), vec2(1.0))).b;

    vec3 blur = base * 4.0;
    blur += sampleClamp(clamp(tape + vec2(px.x, 0.0), vec2(0.0), vec2(1.0)));
    blur += sampleClamp(clamp(tape + vec2(-px.x, 0.0), vec2(0.0), vec2(1.0)));
    blur += sampleClamp(clamp(tape + vec2(0.0, px.y), vec2(0.0), vec2(1.0)));
    blur += sampleClamp(clamp(tape + vec2(0.0, -px.y), vec2(0.0), vec2(1.0)));
    blur *= 0.125;

    float lum = luma(blur);
    float tone = floor(clamp(lum, 0.0, 1.0) * 4.0 + 0.5) / 4.0;
    vec3 cartoon = cartoonPalette(tone);
    float chroma = max(max(blur.r, blur.g), blur.b) - min(min(blur.r, blur.g), blur.b);
    cartoon = mix(vec3(lum), cartoon, 0.70 + chroma * 0.75);
    cartoon = mix(cartoon, blur, 0.11);

    float tl = luma(sampleClamp(clamp(tape + px * vec2(-1.0, -1.0), vec2(0.0), vec2(1.0))));
    float t  = luma(sampleClamp(clamp(tape + px * vec2( 0.0, -1.0), vec2(0.0), vec2(1.0))));
    float tr = luma(sampleClamp(clamp(tape + px * vec2( 1.0, -1.0), vec2(0.0), vec2(1.0))));
    float l  = luma(sampleClamp(clamp(tape + px * vec2(-1.0,  0.0), vec2(0.0), vec2(1.0))));
    float r  = luma(sampleClamp(clamp(tape + px * vec2( 1.0,  0.0), vec2(0.0), vec2(1.0))));
    float bl = luma(sampleClamp(clamp(tape + px * vec2(-1.0,  1.0), vec2(0.0), vec2(1.0))));
    float b  = luma(sampleClamp(clamp(tape + px * vec2( 0.0,  1.0), vec2(0.0), vec2(1.0))));
    float br = luma(sampleClamp(clamp(tape + px * vec2( 1.0,  1.0), vec2(0.0), vec2(1.0))));
    float gx = -tl - 2.0 * l - bl + tr + 2.0 * r + br;
    float gy = -tl - 2.0 * t - tr + bl + 2.0 * b + br;
    float edge = smoothstep(0.16, 0.44, length(vec2(gx, gy)));

    float bands = 0.5 + 0.5 * sin((tape.y * res.y * 0.85) + time_f * 24.0);
    float scanline = 0.78 + 0.22 * sin((tape.y * res.y * 1.25) + time_f * 55.0);
    float noise = hash(floor(gl_FragCoord.xy) + floor(time_f * 60.0)) - 0.5;
    float dropout = step(0.993, hash(vec2(floor(time_f * 18.0), floor(tape.y * 300.0))));
    dropout += smoothstep(0.65, 0.0, mouseDist) * 0.45;
    float smear = smoothstep(0.15, 0.95, bands) * 0.06;

    cartoon *= mix(0.66, 1.12, scanline);
    cartoon += noise * 0.05;
    cartoon -= dropout * vec3(0.12, 0.10, 0.08);
    cartoon += smear * vec3(0.14, 0.06, 0.02);
    cartoon += smoothstep(0.35, 0.0, mouseDist) * vec3(0.08, 0.05, 0.03);

    float shadow = smoothstep(0.76, 0.18, lum);
    float cel = mix(0.32, 1.10, 1.0 - shadow);
    cartoon *= cel;
    cartoon = floor(clamp(cartoon, 0.0, 1.0) * 5.0 + 0.5) / 5.0;

    vec3 ink = vec3(0.02, 0.015, 0.02);
    cartoon = mix(cartoon, ink, edge * 0.93);

    float vignette = smoothstep(1.15, 0.25, length(uv));
    float bleed = 1.0 + 0.045 * sin((tape.y * res.y) + time_f * 14.0);
    cartoon *= vignette * bleed;
    cartoon = mix(cartoon, cartoon * vec3(1.05, 0.98, 0.92), focus * 0.15);

    float blackLevel = 0.012 + 0.02 * (1.0 - vignette);
    cartoon = max(cartoon, vec3(blackLevel));
    cartoon = clamp(cartoon, 0.0, 1.0);

    color = vec4(cartoon, 1.0);
}
