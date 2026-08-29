#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define iamp ext.u1.z
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;










vec3 rainbow(float t) {
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

void main(void) {
    float aLow  = clamp(amp_low,  0.0, 1.0);
    float aMid  = clamp(amp_mid,  0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk   = clamp(amp_peak, 0.0, 1.0);
    float aSmth = clamp(amp_smooth, 0.0, 1.0);

    vec2 centeredCoord = (tc * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);
    float angle = atan(centeredCoord.y, centeredCoord.x) + time_f;
    float radius = length(centeredCoord);

    float spiralFreq = 10.0 + aLow * 15.0;
    float spiralSpeed = mix(2.0, 5.0, aSmth);
    float spiral = sin(spiralFreq * angle - spiralSpeed * time_f) * exp(-3.0 * radius);

    float lightIntensity = 0.3 + aLow * 0.7;
    vec3 lightColor = vec3(0.1 + aLow * 0.4, 0.5 + aMid * 0.3, 0.8 + aHigh * 0.2);
    lightColor *= lightIntensity * (1.0 + spiral);
    lightColor = sin(lightColor * time_f);

    vec4 texColor = texture(samp, tc);

    vec2 uv = tc * 2.0 - 1.0;
    uv.y *= iResolution.y / iResolution.x;
    float t = mod(time_f, 15.0);
    float wave = sin(uv.x * (10.0 + aHigh * 8.0) + t * 2.0) * (0.1 + aPk * 0.15);
    float expand = 0.5 + 0.5 * sin(t * 2.0) + aLow * 0.3;
    vec2 spiral_uv = uv * expand + vec2(cos(t), sin(t)) * 0.2;
    float new_angle = atan(spiral_uv.y + wave, spiral_uv.x) + t * 2.0;
    vec3 rainbow_color = rainbow(new_angle / 6.28318 + aMid * 0.5);

    float blendAmt = 0.4 + aMid * 0.3;
    vec3 blended_color = mix(texColor.rgb * lightColor, rainbow_color, blendAmt);

    blended_color *= 1.0 + aPk * 0.6;

    color = vec4(sin(blended_color * t), texColor.a);
}
