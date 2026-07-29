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
