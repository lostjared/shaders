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

float fractal(vec2 z, float time, int maxIter) {
    float iterations = 0.0;
    vec2 c = vec2(sin(time * 0.3), cos(time * 0.2));
    for (int i = 0; i < 80; i++) {
        if (i >= maxIter)
            break;
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        if (length(z) > 2.0)
            break;
        iterations += 1.0;
    }
    return iterations / float(maxIter);
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float aRms = clamp(amp_rms, 0.0, 1.0);

    vec2 uv = tc * 2.0 - 1.0;
    uv.y *= iResolution.y / iResolution.x;

    float zoom = 1.0 + aLow * 0.8;
    uv *= zoom;

    int iters = 30 + int(aRms * 40.0);
    float speed = mix(0.4, 1.5, aRms);
    float fractalValue = fractal(uv, time_f * speed, iters);

    float hueOffset = aHigh * 1.5;
    vec3 fractalColor = rainbow(fractalValue + time_f * 0.1 + hueOffset);

    float time_t = pingPong(time_f, 15.0) + 1.0;
    float r = length(uv);
    float theta = atan(uv.y, uv.x);
    float spiralSpeed = mix(3.0, 7.0, aMid);
    theta += time_f * spiralSpeed + r * (10.0 + aLow * 10.0);
    vec2 spiralUV = vec2(cos(theta), sin(theta)) * r;

    vec4 tex = texture(samp, tc);
    vec3 blended = mix(tex.rgb, fractalColor, 0.5 + aMid * 0.3);

    blended *= 1.0 + aPk * 0.7;
    blended = mix(blended,
                  blended * vec3(1.2 + aLow * 0.3, 0.9, 1.0 + aHigh * 0.4),
                  aPk);

    color = vec4(sin(blended * time_t), tex.a);
}
