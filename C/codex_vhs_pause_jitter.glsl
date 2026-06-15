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
    float frame = floor(t * 8.0);
    float jitter = (hash(frame) - 0.5) * 0.012;
    uv += vec2(jitter, (hash(frame + 9.0) - 0.5) * 0.006);
    float row = floor(uv.y * max(iResolution.y, 1.0) * 0.5);
    uv.x += (hash(row + frame * 3.0) - 0.5) * 0.006;
    uv.x += (mouseUV.x - uv.x) * smoothstep(1.0, 0.0, distance(tc, mouseUV)) * 0.02;
    vec3 c = texture(samp, clamp(uv, 0.0, 1.0)).rgb;
    float comb = step(0.5, fract(gl_FragCoord.y * 0.5));
    c = mix(c * 0.78, c * 1.08, comb * 0.45);
    float noise = hash(gl_FragCoord.x + gl_FragCoord.y * 71.0 + frame);
    c += (noise - 0.5) * 0.08;
    color = vec4(c, 1.0);
}
