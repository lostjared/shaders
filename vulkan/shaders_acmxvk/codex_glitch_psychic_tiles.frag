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
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;




float hash(vec2 p) { return fract(sin(dot(p, vec2(113.1, 271.9))) * 43758.5453); }
vec2 wrapMirror(vec2 p) { return abs(fract(p) * 2.0 - 1.0); }

void main(void) {
    float t = time_f;
    vec2 grid = vec2(14.0, 10.0);
    vec2 cell = floor(tc * grid);
    vec2 f = fract(tc * grid) - 0.5;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseCell = floor(mouseUV * grid);
    float mousePull = smoothstep(3.5, 0.0, distance(cell, mouseCell));
    float h = hash(cell + floor(t * 3.0));
    vec2 q = f;
    for (int i = 0; i < 4; ++i) {
        q = abs(q * (1.55 + 0.1 * h)) - 0.42;
        q = mat2(0.71, -0.71, 0.71, 0.71) * q;
    }
    q += (mouseUV - (cell + 0.5) / grid) * mousePull * 0.45;
    vec2 uv = (cell + 0.5 + q + vec2((h - 0.5) * 0.35, 0.0)) / grid;
    uv += vec2(sin(cell.y + t * 4.0), cos(cell.x - t * 3.0)) * 0.01;
    vec3 c = texture(samp, wrapMirror(uv)).rgb;
    float edge = smoothstep(0.48, 0.38, max(abs(f.x), abs(f.y)));
    vec3 aura = 0.5 + 0.5 * cos(vec3(0.1, 2.4, 4.8) + h * 8.0 + length(q) * 12.0);
    color = vec4(mix(aura * 0.15, c * aura + aura * 0.25, edge), 1.0);
}
