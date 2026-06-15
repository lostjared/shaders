#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(19.19, 73.73))) * 45758.5453);
}

void main(void) {
    float t = time_f;
    vec2 uv = tc;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    float row = floor(uv.y * 160.0);
    float dropout = smoothstep(0.91, 1.0, hash(vec2(row, floor(t * 9.0))));
    float segment = smoothstep(0.2, 0.95, hash(vec2(floor(uv.x * 18.0), row)));
    float mask = dropout * segment;
    mask += smoothstep(1.0, 0.0, distance(tc, mouseUV)) * 0.4;
    uv.x += mask * (hash(vec2(row, t)) - 0.5) * 0.07;
    vec3 c = texture(samp, clamp(uv, 0.0, 1.0)).rgb;
    float gray = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(c, vec3(gray) * 1.25 + vec3(0.08), mask * 0.72);
    c += mask * vec3(hash(gl_FragCoord.xy + t * 100.0)) * 0.22;
    c *= 0.88 + 0.12 * sin(tc.y * iResolution.y * 3.14159);
    color = vec4(c, 1.0);
}
