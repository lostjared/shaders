#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec2 iMouse;

vec3 rainbow(float t) {
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

void main() {
    vec2 mouse = iMouse / iResolution;
    mouse.y = 1.0 - mouse.y;
    vec2 uv = tc - mouse;
    uv.y *= iResolution.y / iResolution.x;
    float angle = atan(uv.y, uv.x) + time_f * 8.0;
    float radius = length(uv);
    vec3 rc = rainbow(angle / (2.0 * 3.14159));
    vec4 tex = texture(samp, tc);
    float falloff = smoothstep(0.5, 0.0, radius);
    vec3 outc = mix(tex.rgb, rc, falloff);
    color = vec4(outc, tex.a);
}
