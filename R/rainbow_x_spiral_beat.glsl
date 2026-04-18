#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

vec3 rainbow(float t) {
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    float aLow  = clamp(amp_low,  0.0, 1.0);
    float aMid  = clamp(amp_mid,  0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk   = clamp(amp_peak, 0.0, 1.0);
    float aSmth = clamp(amp_smooth, 0.0, 1.0);

    vec2 uv = tc * 2.0 - 1.0;
    uv.y *= iResolution.y / iResolution.x;

    float r = length(uv);
    float theta = atan(uv.y, uv.x);

    float spiralTight = 15.0 + aLow * 20.0;
    float spiralSpeed = mix(3.0, 8.0, aSmth);
    theta += time_f * spiralSpeed + r * spiralTight;

    uv = vec2(cos(theta), sin(theta)) * r;

    float hueShift = aHigh * 2.0;
    vec3 rainbow_color = rainbow(uv.x + uv.y + time_f * 0.5 + hueShift);

    vec4 tex = texture(samp, tc);

    float beatPulse = 1.0 + aPk * 0.6;
    vec3 blended = mix(tex.rgb, rainbow_color, 0.4 + aMid * 0.3);
    blended *= beatPulse;

    float time_t = pingPong(time_f, 15.0) + 1.0;
    blended = mix(blended,
                  blended * vec3(1.0 + aLow * 0.3, 1.0 - aLow * 0.1, 1.0 + aHigh * 0.25),
                  aPk);

    color = vec4(sin(blended * time_t), tex.a);
}
