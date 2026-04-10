#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

vec4 blur(sampler2D image, vec2 uv, vec2 resolution) {
    vec2 texelSize = 1.0 / resolution;
    vec4 result = vec4(0.0);
    float kernel[100];
    float kernelVals[100] = float[](0.5,1.0,1.5,2.0,2.5,2.5,2.0,1.5,1.0,0.5,
                                    1.0,2.0,2.5,3.0,3.5,3.5,3.0,2.5,2.0,1.0,
                                    1.5,2.5,3.0,3.5,4.0,4.0,3.5,3.0,2.5,1.5,
                                    2.0,3.0,3.5,4.0,4.5,4.5,4.0,3.5,3.0,2.0,
                                    2.5,3.5,4.0,4.5,5.0,5.0,4.5,4.0,3.5,2.5,
                                    2.5,3.5,4.0,4.5,5.0,5.0,4.5,4.0,3.5,2.5,
                                    2.0,3.0,3.5,4.0,4.5,4.5,4.0,3.5,3.0,2.0,
                                    1.5,2.5,3.0,3.5,4.0,4.0,3.5,3.0,2.5,1.5,
                                    1.0,2.0,2.5,3.0,3.5,3.5,3.0,2.5,2.0,1.0,
                                    0.5,1.0,1.5,2.0,2.5,2.5,2.0,1.5,1.0,0.5);
    for (int i = 0; i < 100; i++) kernel[i] = kernelVals[i];

    float kernelSum = 0.0;
    for (int i = 0; i < 100; i++) kernelSum += kernel[i];

    for (int x = -5; x <= 4; ++x) {
        for (int y = -5; y <= 4; ++y) {
            vec2 offset = vec2(float(x), float(y)) * texelSize;
            result += texture(image, uv + offset) * kernel[(y + 5) * 10 + (x + 5)];
        }
    }
    return result / kernelSum;
}

void main(void) {
    float time_t = pingPong(time_f, 10.0) + 2.0;

    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    float dist = length((tc - m) * ar);
    float radius = 0.45;
    float w = 1.0 - smoothstep(0.0, radius, dist);

    float baseGlitch = 0.001;
    float glitchStrength = mix(baseGlitch, baseGlitch * 4.0, w);

    vec2 uv = tc;
    uv.x += (rand(uv + time_f) - 0.5) * glitchStrength;
    uv.y += (rand(uv + time_f * 1.5) - 0.5) * glitchStrength;

    float band = (rand(vec2(floor(tc.y * iResolution.y) + floor(time_f * 30.0))) - 0.5) * glitchStrength * 6.0 * w;
    uv.x += band;

    vec4 texColor = blur(samp, uv, iResolution);

    vec4 colorShift = vec4(texColor.r,
                           texColor.g * 0.5 + 0.5,
                           texColor.b * 0.5 + 0.5,
                           texColor.a);

    colorShift = sin(colorShift * time_t);

    float glitchNoise = rand(uv + time_f);
    vec4 glitchColor = vec4(vec3(glitchNoise), 1.0) * glitchStrength;

    color = mix(colorShift, glitchColor, glitchStrength * glitchNoise);
    color = sin(color * time_t);
    color.a = 1.0;
}
