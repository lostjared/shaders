#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define alpha ext.u0.x
#define alpha_b ext.custom_uniforms[1].x
#define alpha_g ext.custom_uniforms[0].w
#define alpha_r ext.custom_uniforms[0].z
#define alpha_value ext.custom_uniforms[0].y
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define index_value ext.custom_uniforms[2].x
#define restore_black ext.custom_uniforms[2].y
#define time_f ext.u2.y
#define value_alpha_b ext.custom_uniforms[1].w
#define value_alpha_g ext.custom_uniforms[1].z
#define value_alpha_r ext.custom_uniforms[1].y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;




uniform vec4 optx;
uniform vec4 random_var;

uniform mat4 mv_matrix;
uniform mat4 proj_matrix;
layout(set = 0, binding = 0) uniform sampler2D samp;






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

void main(void)
{
    vec2 res = max(iResolution, vec2(1.0));
    vec2 px = 1.0 / res;
    vec4 src = texture(samp, tc);
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / res) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= res.x / res.y;
    vec2 p = tc * 2.0 - 1.0;
    p.x *= res.x / res.y;
    float mouseFocus = smoothstep(1.35, 0.0, length(p - mouseP));

    vec3 soft = src.rgb * 4.0;
    soft += sampleClamp(tc + vec2( px.x,  0.0));
    soft += sampleClamp(tc + vec2(-px.x,  0.0));
    soft += sampleClamp(tc + vec2( 0.0,  px.y));
    soft += sampleClamp(tc + vec2( 0.0, -px.y));
    soft *= 0.125;

    float lum = luma(soft);
    float shade = 0.24;
    if (lum > 0.78) {
        shade = 1.08;
    } else if (lum > 0.55) {
        shade = 0.82;
    } else if (lum > 0.33) {
        shade = 0.56;
    }

    vec3 hue = soft / max(lum, 0.001);
    vec3 toon = hue * shade;
    toon = floor(clamp(toon, 0.0, 1.0) * 6.0 + 0.5) / 6.0;
    toon = mix(vec3(luma(toon)), toon, 1.35);
    toon += mouseFocus * 0.08;

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
    float ink = smoothstep(0.18, 0.48, length(vec2(gx, gy)));

    float hatch = step(0.55, fract((gl_FragCoord.x + gl_FragCoord.y) * 0.22));
    float shadowHatch = hatch * smoothstep(0.46, 0.18, lum) * 0.10;
    float paper = (hash(floor(gl_FragCoord.xy * 0.5) + floor(time_f * 2.0)) - 0.5) * 0.035;
    paper += mouseFocus * 0.02;

    toon -= shadowHatch;
    toon += paper;
    toon = mix(toon, vec3(0.015, 0.012, 0.01), ink * 0.92);

    color = vec4(clamp(toon, 0.0, 1.0), src.a);
}
