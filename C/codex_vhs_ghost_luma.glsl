#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    float t = time_f;
    vec2 px = 1.0 / max(iResolution, vec2(1.0));
    vec2 uv = tc + vec2(sin(tc.y * 45.0 + t * 3.0) * px.x * 3.0, 0.0);
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    uv += (mouseUV - tc) * smoothstep(1.0, 0.0, distance(tc, mouseUV)) * 0.02;
    vec3 c = texture(samp, clamp(uv, 0.0, 1.0)).rgb;
    vec3 ghost1 = texture(samp, clamp(uv + vec2(px.x * 18.0, 0.0), 0.0, 1.0)).rgb;
    vec3 ghost2 = texture(samp, clamp(uv - vec2(px.x * 33.0, 0.0), 0.0, 1.0)).rgb;
    float l1 = dot(ghost1, vec3(0.299, 0.587, 0.114));
    float l2 = dot(ghost2, vec3(0.299, 0.587, 0.114));
    c += vec3(l1) * vec3(0.10, 0.13, 0.18);
    c += vec3(l2) * vec3(0.11, 0.08, 0.05);
    c *= vec3(1.04, 0.97, 0.9);
    c *= 0.84 + 0.16 * sin(tc.y * iResolution.y * 3.14159);
    color = vec4(c, 1.0);
}
