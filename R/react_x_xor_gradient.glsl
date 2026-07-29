#version 330 core
out vec4 color;
in vec2 tc;

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

vec4 xor_RGB(vec4 icolor, vec4 source) {
    ivec3 int_color;
    ivec4 isource = ivec4(source * 255);
    for (int i = 0; i < 3; ++i) {
        int_color[i] = int(255 * icolor[i]);
        int_color[i] = int_color[i] ^ isource[i];
        if (int_color[i] > 255)
            int_color[i] = int_color[i] % 255;
        icolor[i] = float(int_color[i]) / 255;
    }
    icolor.a = 1.0;
    return icolor;
}

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

vec4 blur5(sampler2D image, vec2 uv, vec2 resolution, float strength) {
    vec2 texelSize = strength / resolution;
    vec4 result = vec4(0.0);
    float total = 0.0;
    for (int x = -2; x <= 2; ++x) {
        for (int y = -2; y <= 2; ++y) {
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

    float amplitude = aRms * 0.8 + 0.1;
    vec3 gradLow  = vec3(0.0, 0.2, 1.0) * (0.5 + aLow * 0.5);
    vec3 gradHigh = vec3(1.0, 0.1, 0.2) * (0.5 + aHigh * 0.5);
    vec3 gradientColor = mix(gradLow, gradHigh, amplitude);

    float blurStr = 1.0 + aPk * 3.0;
    vec4 texColor = blur5(samp, tc, iResolution, blurStr);

    vec2 uv = tc / iResolution;
    float gradMix = 0.5 * sin(time_f * (1.0 + aMid * 2.0) + uv.y * 3.14159) + 0.5;
    gradMix *= 0.3 + aMid * 0.4;
    vec3 finalColor = mix(texColor.rgb, gradientColor, gradMix);

    color = vec4(finalColor, texColor.a);
    float time_t = pingPong(time_f, 10.0) + 0.5;
    vec4 blurred = blur5(samp, tc, iResolution, 1.0 + aLow * 2.0);
    color = xor_RGB(color, blurred * time_t);

    color.rgb *= 1.0 + aPk * 0.5;
    color.rgb = mix(color.rgb,
                    color.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.3),
                    aPk);
}
