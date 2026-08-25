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




void main(void) {
    float t = time_f;
    vec2 px = 1.0 / max(iResolution, vec2(1.0));
    vec2 uv = tc;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    float drift = sin(uv.y * 36.0 + t * 2.0) * 3.0 + sin(t * 0.7) * 5.0;
    drift += smoothstep(1.0, 0.0, distance(tc, mouseUV)) * 2.5;
    vec3 center = texture(samp, uv).rgb;
    vec3 left = texture(samp, clamp(uv - vec2(px.x * (7.0 + drift), 0.0), 0.0, 1.0)).rgb;
    vec3 right = texture(samp, clamp(uv + vec2(px.x * (7.0 - drift), 0.0), 0.0, 1.0)).rgb;
    float y = dot(center, vec3(0.299, 0.587, 0.114));
    vec3 c = vec3(y);
    c.r += (right.r - y) * 1.55;
    c.g += (center.g - y) * 0.85;
    c.b += (left.b - y) * 1.65;
    float scan = 0.88 + 0.12 * sin(uv.y * iResolution.y * 3.14159);
    color = vec4(c * scan, 1.0);
}
