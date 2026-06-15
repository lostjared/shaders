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
    float line = floor(uv.y * max(iResolution.y, 1.0));
    float jump = (hash(line * 0.17 + floor(t * 12.0)) - 0.5) * 0.018;
    float tear = smoothstep(0.92, 1.0, hash(floor(uv.y * 48.0) + floor(t * 5.0)));
    uv.x += jump * tear + sin(uv.y * 90.0 + t * 9.0) * 0.003;
    uv.x += (mouseUV.x - uv.x) * smoothstep(1.0, 0.0, distance(tc, mouseUV)) * 0.02;
    vec2 px = 1.0 / max(iResolution, vec2(1.0));
    float split = 2.5 + 8.0 * tear;
    vec3 c;
    c.r = texture(samp, clamp(uv + vec2(px.x * split, 0.0), 0.0, 1.0)).r;
    c.g = texture(samp, clamp(uv, 0.0, 1.0)).g;
    c.b = texture(samp, clamp(uv - vec2(px.x * split, 0.0), 0.0, 1.0)).b;
    float scan = 0.82 + 0.18 * sin(uv.y * iResolution.y * 3.14159);
    float snow = hash(gl_FragCoord.x + gl_FragCoord.y * 113.0 + floor(t * 60.0));
    c = c * scan + vec3(snow) * tear * 0.18;
    color = vec4(c, 1.0);
}
