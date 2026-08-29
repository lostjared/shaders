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










float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void) {
    vec2 uv = tc;
    vec4 texColor = texture(samp, uv);
    
    float starDensity = 0.01;
    float starSize = 0.03;
    vec2 gridPos = floor(uv * iResolution.xy * starDensity);
    vec2 starPos = fract(uv * iResolution.xy * starDensity);
    
    float starNoise = rand(gridPos);
    float starIntensity = smoothstep(starSize, starSize * 0.5, distance(starPos, vec2(starNoise, fract(sin(time_f + starNoise) * 0.5 + 0.5))));
    
    float twinkleSpeed = 10.0 + amp_high * 30.0;
    starIntensity *= 0.5 + 0.5 * sin(time_f * twinkleSpeed + starNoise * 100.0);
    
    vec4 starColor = vec4(vec3(starIntensity), starIntensity);
    
    color = mix(texColor, starColor, starColor.a);

    // --- Audio Reactivity: direct output modulation ---
    float _ab = clamp(amp_peak, 0.0, 1.0);
    float _abass = clamp(amp_low, 0.0, 1.0);
    color.rgb *= 1.0 + _ab * 0.6;
    color.rgb = mix(color.rgb, color.rgb * vec3(1.0 + _abass * 0.3, 1.0 - _abass * 0.15, 1.0 + clamp(amp_high, 0.0, 1.0) * 0.25), _ab);
    // --- End Audio Reactivity ---

}
