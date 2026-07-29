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

vec4 blur(sampler2D image, vec2 uv, vec2 resolution, float strength) {
    vec2 texelSize = strength / resolution;
    vec4 result = vec4(0.0);
    float total = 0.0;
    for (int x = -4; x <= 4; ++x) {
        for (int y = -4; y <= 4; ++y) {
            float w = 1.0 / (1.0 + float(x * x + y * y));
            result += texture(image, uv + vec2(float(x), float(y)) * texelSize) * w;
            total += w;
        }
    }
    return result / total;
}

void main(void) {
    float aLow  = clamp(amp_low,  0.0, 1.0);
    float aMid  = clamp(amp_mid,  0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk   = clamp(amp_peak, 0.0, 1.0);
    float aRms  = clamp(amp_rms,  0.0, 1.0);

    vec2 uv = tc * 2.0 - 1.0;
    uv.y *= iResolution.y / iResolution.x;

    float time_t = pingPong(time_f, 15.0) + 1.0;
    float wave = sin(uv.x * (8.0 + aLow * 12.0) + time_t * 2.0) * 0.1;
    float expand = 0.5 + 0.5 * sin(time_t * 2.0) + aLow * 0.3;
    vec2 spiral_uv = uv * expand;

    float speed = mix(0.5, 2.0, aRms);
    vec3 rainbow_color = rainbow(uv.x + sin(time_f * speed + uv.y * (5.0 + aHigh * 10.0)) * 0.1);

    float blurStr = 1.0 + aPk * 4.0;
    vec4 blurred_color = blur(samp, tc, iResolution, blurStr);

    float rainbowMix = 0.3 + 0.4 * aMid;
    vec3 blended_color = mix(blurred_color.rgb, rainbow_color, rainbowMix);

    blended_color *= 1.0 + aPk * 0.8;
    blended_color = mix(blended_color,
                        blended_color * vec3(1.0 + aLow * 0.4, 1.0, 1.0 + aHigh * 0.3),
                        aPk);

    color = vec4(sin(blended_color * time_t), blurred_color.a);
}
