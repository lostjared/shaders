#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) { return fract(sin(dot(p, vec2(11.7, 77.3))) * 43758.5453); }
vec3 palette(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (vec3(0.72, 0.04, 0.38) + t));
}

void main(void) {
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= aspect;
    p -= mouseP * 0.08;
    float a = atan(p.y, p.x);
    float r = length(p);
    vec2 dir = vec2(cos(a), sin(a));
    float shardSignal = sin(a * 11.0) * 0.5 + cos(a * 7.0) * 0.5;
    float shard = floor((shardSignal + 1.0) * 11.0);
    float h = hash(vec2(shard, floor(time_f * 2.0)));
    vec2 z = mat2(cos(h * 0.45), -sin(h * 0.45), sin(h * 0.45), cos(h * 0.45)) * dir * r;
    for (int i = 0; i < 4; ++i) z = abs(z * (1.7 + h * 0.2)) - vec2(0.52, 0.33);
    float edge = smoothstep(0.03, 0.0, abs(z.x + z.y));
    vec2 uv = abs(fract(z / vec2(aspect, 1.0) + 0.5) * 2.0 - 1.0);
    uv += (mouseP - p) * 0.03 * smoothstep(1.25, 0.0, length(p - mouseP));
    vec3 tex = texture(samp, uv).rgb;
    vec3 grad = palette(r * 0.6 + h + edge * 0.2 - time_f * 0.05) * vec3(1.1, 0.62, 1.35);
    color = vec4(mix(tex, grad, 0.74) + grad * edge * 0.85, 1.0);
}
