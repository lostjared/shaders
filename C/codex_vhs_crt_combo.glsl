#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 uv = tc * 2.0 - 1.0;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= iResolution.x / max(iResolution.y, 1.0);
    vec2 curve = uv.yx * uv.yx;
    uv += uv * curve * 0.075;
    uv += (mouseP - uv) * smoothstep(1.35, 0.0, length(uv - mouseP)) * 0.04;
    uv = uv * 0.5 + 0.5;
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        color = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }
    uv.x += sin(uv.y * 70.0 + time_f * 5.0) * 0.0025;
    uv.x += (mouseUV.x - uv.x) * smoothstep(1.0, 0.0, distance(tc, mouseUV)) * 0.015;
    vec3 c = texture(samp, uv).rgb;
    float scan = 0.72 + 0.28 * sin(uv.y * iResolution.y * 3.14159);
    float slot = mod(gl_FragCoord.x + floor(gl_FragCoord.y), 3.0);
    vec3 mask = vec3(slot < 1.0 ? 1.12 : 0.82,
                     slot >= 1.0 && slot < 2.0 ? 1.08 : 0.84,
                     slot >= 2.0 ? 1.14 : 0.82);
    float vignette = smoothstep(1.15, 0.25, length(tc - 0.5));
    color = vec4(c * scan * mask * vignette, 1.0);
}
