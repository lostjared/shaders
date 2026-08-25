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




float hash(vec2 p) { return fract(sin(dot(p, vec2(89.4, 23.7))) * 43758.5453); }
vec2 wrapMirror(vec2 p) { return abs(fract(p) * 2.0 - 1.0); }

void main(void) {
    float t = time_f;
    vec2 p = tc - 0.5;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= iResolution.x / max(iResolution.y, 1.0);
    p -= mouseP * 0.08;
    vec2 q = p;
    float mask = 0.0;
    for (int i = 0; i < 6; ++i) {
        q = abs(q * (1.38 + 0.08 * sin(t + float(i)))) - 0.33;
        mask += step(0.47, fract((q.x + q.y) * 12.0 + float(i) + t));
    }
    float bands = floor(tc.y * 64.0);
    float jump = (hash(vec2(bands, floor(t * 12.0))) - 0.5) * step(3.0, mask);
    vec2 uv = wrapMirror(tc + q * 0.05 + vec2(jump * 0.16, 0.0));
    uv += (mouseP - p) * 0.02 * smoothstep(1.25, 0.0, length(p - mouseP));
    vec3 a = texture(samp, uv).rgb;
    vec3 b = texture(samp, wrapMirror(uv.yx + 0.17 * sin(t))).bgr;
    vec3 xorish = abs(a - b);
    vec3 acid = 0.5 + 0.5 * cos(vec3(0.0, 2.4, 4.8) + mask + t * 3.0);
    color = vec4(mix(a, xorish * acid + acid * 0.18, 0.68), 1.0);
}
