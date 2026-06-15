#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) { return fract(sin(dot(p, vec2(17.17, 91.71))) * 43758.5453); }
vec2 wrapMirror(vec2 p) { return abs(fract(p) * 2.0 - 1.0); }

void main(void) {
    float t = time_f;
    vec2 uv = tc;
    vec2 p = uv - 0.5;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= iResolution.x / max(iResolution.y, 1.0);
    p -= mouseP * 0.08;
    for (int i = 0; i < 6; ++i) {
        p = abs(p * (1.18 + 0.04 * sin(t + float(i)))) - vec2(0.31, 0.27);
        p += 0.025 * sin(p.yx * (8.0 + float(i)) + t);
    }
    float blocks = hash(vec2(floor(tc.x * 24.0), floor(tc.y * 40.0) + floor(t * 9.0)));
    float burn = smoothstep(0.76, 1.0, blocks) * smoothstep(0.04, 0.0, abs(p.x * p.y));
    uv = wrapMirror(tc + p * 0.04 + vec2(burn * 0.12, 0.0));
    uv += (mouseP - p) * 0.025 * smoothstep(1.25, 0.0, length(p - mouseP));
    vec3 c = texture(samp, uv).rgb;
    float scan = 0.75 + 0.25 * sin(tc.y * iResolution.y * 3.14159 + burn * 8.0);
    vec3 hot = vec3(1.0, 0.05, 0.65) + vec3(0.0, 0.8, 1.0) * sin(t + p.x * 10.0);
    color = vec4(c * scan + hot * burn * 0.45, 1.0);
}
