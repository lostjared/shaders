#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(53.7, 141.9))) * 43758.5453);
}

void main(void) {
    float t = time_f;
    vec2 uv = tc;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= iResolution.x / max(iResolution.y, 1.0);
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / max(iResolution.y, 1.0);
    uv += (mouseUV - tc) * smoothstep(1.0, 0.0, distance(tc, mouseUV)) * 0.02;
    uv.x += sin(uv.y * 52.0 + t * 2.5) * 0.004;
    vec3 original = texture(samp, clamp(uv, 0.0, 1.0)).rgb;
    float luma = dot(original, vec3(0.299, 0.587, 0.114));
    vec3 blueBlack = vec3(0.02, 0.035, 0.09);
    vec3 amberHi = vec3(1.0, 0.72, 0.42);
    vec3 c = mix(original, mix(blueBlack, amberHi, smoothstep(0.05, 0.95, luma)), 0.58);
    float band = sin(uv.y * 18.0 - t * 1.3) * 0.5 + 0.5;
    float dirt = hash(floor(gl_FragCoord.xy / vec2(3.0, 1.0)) + floor(t * 24.0));
    c *= 0.68 + band * 0.32;
    c += (dirt - 0.5) * 0.11;
    c *= 0.82 + 0.18 * sin(tc.y * iResolution.y * 3.14159);
    color = vec4(c, 1.0);
}
