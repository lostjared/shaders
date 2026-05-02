#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void) {
    vec3 tex = texture(samp, tc).rgb;
    vec3 hsv = rgb2hsv(tex);

    // Mids drive hue orbit speed
    float hueSpeed = time_f * (0.05 + amp_mid * 0.4);
    hsv.x = fract(hsv.x + hueSpeed);

    // Bass pumps saturation
    hsv.y = clamp(hsv.y * (1.0 + amp_low * 0.8), 0.0, 1.0);

    // Treble boosts value/brightness
    hsv.z = clamp(hsv.z * (1.0 + amp_high * 0.4), 0.0, 1.0);

    // RMS adds position-dependent hue offset (rainbow sweep)
    float posHue = (tc.x + tc.y) * 0.5;
    hsv.x = fract(hsv.x + posHue * amp_rms * 0.3);

    // Peak desaturation flash (white flash on transients)
    float peakFlash = smoothstep(0.6, 1.0, amp_peak);
    hsv.y *= 1.0 - peakFlash * 0.5;
    hsv.z = min(hsv.z + peakFlash * 0.3, 1.0);

    vec3 col = hsv2rgb(hsv);

    // Smooth amp adds warm undertone
    col += amp_smooth * 0.05 * vec3(1.0, 0.7, 0.3);

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
