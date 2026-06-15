#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

float hash(float n) {
    return fract(sin(n) * 9917.231);
}

void main(void) {
    float t = time_f;
    vec2 uv = tc;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    float switchZone = smoothstep(0.0, 0.10, uv.y) * (1.0 - smoothstep(0.18, 0.28, uv.y));
    float chatter = hash(floor(t * 24.0)) - 0.5;
    float mouseZone = smoothstep(1.0, 0.0, distance(tc, mouseUV));
    uv.x += switchZone * (0.08 * chatter + 0.035 * sin(uv.y * 220.0 + t * 18.0));
    uv.y += switchZone * 0.018 * sin(uv.x * 90.0 + t * 9.0);
    uv.x += mouseZone * 0.04 * sin(uv.y * 180.0 + t * 14.0);
    vec3 c = texture(samp, clamp(uv, 0.0, 1.0)).rgb;
    float whiteTear = switchZone * smoothstep(0.3, 1.0, hash(floor(uv.y * 120.0) + floor(t * 30.0)));
    c = mix(c, vec3(0.95), whiteTear * 0.35);
    c *= 0.82 + 0.18 * sin(tc.y * iResolution.y * 3.14159);
    color = vec4(c, 1.0);
}
