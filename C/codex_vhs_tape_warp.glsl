#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    float t = time_f;
    vec2 uv = tc;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    float bend = pow(abs(uv.y - 0.5) * 2.0, 2.0);
    uv.x += sin(uv.y * 18.0 + t * 1.8) * 0.018 * bend;
    uv.x += sin(uv.y * 240.0 + t * 17.0) * 0.0025;
    uv.y += sin(uv.x * 12.0 - t * 1.2) * 0.006 * bend;
    uv += (mouseUV - uv) * smoothstep(1.0, 0.0, distance(tc, mouseUV)) * 0.02;
    vec2 px = 1.0 / max(iResolution, vec2(1.0));
    vec3 c = vec3(0.0);
    c += texture(samp, clamp(uv - px * vec2(2.0, 0.0), 0.0, 1.0)).rgb * 0.22;
    c += texture(samp, clamp(uv, 0.0, 1.0)).rgb * 0.56;
    c += texture(samp, clamp(uv + px * vec2(2.0, 0.0), 0.0, 1.0)).rgb * 0.22;
    c *= vec3(0.95, 0.98, 1.06);
    c *= 0.8 + 0.2 * smoothstep(0.0, 0.25, uv.y) * smoothstep(1.0, 0.75, uv.y);
    color = vec4(c, 1.0);
}
