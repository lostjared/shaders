#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

void main(void) {
    float t = time_f;
    vec2 uv = tc;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    float roll = fract(t * 0.18);
    uv.y = fract(uv.y + roll);
    float line = floor(uv.y * max(iResolution.y, 1.0));
    float wobble = sin(uv.y * 85.0 + t * 8.0) * 0.004;
    float tear = smoothstep(0.89, 1.0, hash(floor(uv.y * 28.0) + floor(t * 7.0)));
    uv.x += wobble + (hash(line * 0.03 + floor(t * 12.0)) - 0.5) * 0.035 * tear;
    uv.y += (mouseUV.y - uv.y) * smoothstep(1.0, 0.0, distance(tc, mouseUV)) * 0.02;
    vec2 px = 1.0 / max(iResolution, vec2(1.0));
    vec3 c;
    c.r = texture(samp, clamp(uv + vec2(px.x * 3.0, 0.0), 0.0, 1.0)).r;
    c.g = texture(samp, clamp(uv, 0.0, 1.0)).g;
    c.b = texture(samp, clamp(uv - vec2(px.x * 3.0, 0.0), 0.0, 1.0)).b;
    float band = smoothstep(0.015, 0.0, abs(tc.y - 0.5 + sin(t * 0.9) * 0.42));
    float scan = 0.82 + 0.18 * sin(tc.y * iResolution.y * 3.14159);
    color = vec4(c * scan + vec3(band * 0.28), 1.0);
}
