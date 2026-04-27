#version 330 core
// Subtle CRT curvature with scanlines and mild RGB mask. Good for retro games.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 uv = tc * 2.0 - 1.0;
    vec2 off = uv.yx * uv.yx;
    uv += uv * off * 0.05;
    uv = uv * 0.5 + 0.5;
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        color = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }
    vec3 c = texture(samp, uv).rgb;
    float scan = 0.92 + 0.08 * sin(uv.y * iResolution.y * 3.14159);
    float mask = mod(gl_FragCoord.x, 3.0);
    vec3 rgbMask = vec3(mask < 1.0 ? 1.05 : 0.95,
                        mask < 2.0 && mask >= 1.0 ? 1.05 : 0.95,
                        mask >= 2.0 ? 1.05 : 0.95);
    c *= scan * rgbMask;
    color = vec4(c, 1.0);
}
