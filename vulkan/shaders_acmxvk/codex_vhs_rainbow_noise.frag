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




float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main(void) {
    float t = time_f;
    vec2 uv = tc;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec3 c = texture(samp, uv).rgb;
    float n = hash(floor(vec2(gl_FragCoord.x * 0.5, gl_FragCoord.y) + t * 60.0));
    float streak = smoothstep(0.965, 1.0, hash(vec2(floor(uv.y * 90.0), floor(t * 10.0))));
    streak += smoothstep(1.0, 0.0, distance(tc, mouseUV)) * 0.25;
    vec3 rainbow = 0.5 + 0.5 * cos(vec3(0.0, 2.1, 4.2) + uv.x * 18.0 + t * 6.0 + n * 4.0);
    c = mix(c, rainbow, streak * 0.45);
    c += (n - 0.5) * (0.16 + streak * 0.25);
    c *= 0.86 + 0.14 * sin(uv.y * iResolution.y * 3.14159);
    color = vec4(c, 1.0);
}
