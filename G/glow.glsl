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

vec4 xor_RGB(vec4 icolor, vec4 source) {
    ivec3 int_color;
    ivec4 isource = ivec4(source * 255);
    for(int i = 0; i < 3; ++i) {
        int_color[i] = int(255 * icolor[i]);
        int_color[i] = int_color[i]^isource[i];
        if(int_color[i] > 255)
            int_color[i] = int_color[i]%255;
        icolor[i] = float(int_color[i])/255;
    }
    icolor.a = 1.0;
return icolor;
}


void main(void) {
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    
    float dist = sin(length(uv) * time_f);
    
    float glowFrequency = 15.0 + amp_high * 20.0;
    float glowSpeed = 10.0;

    float glow = sin(dist * glowFrequency - time_f * glowSpeed) * 0.5 + 0.5;

    float expansion = abs(sin(time_f * (0.5 + amp_low * 2.0)));
    float beam = smoothstep(0.0, 1.0, expansion - dist);

    vec3 beamColor = vec3(0.0, 0.8, 1.0);
    vec3 glowColor = vec3(1.0, 1.0, 1.0);

    vec3 finalColor = mix(beamColor, glowColor, glow) * beam;
    

    // --- Audio Reactivity: direct output modulation ---
    float _ab = clamp(amp_peak, 0.0, 1.0);
    float _abass = clamp(amp_low, 0.0, 1.0);
    finalColor *= 1.0 + _ab * 0.6;
    finalColor = mix(finalColor, finalColor * vec3(1.0 + _abass * 0.3, 1.0 - _abass * 0.15, 1.0 + clamp(amp_high, 0.0, 1.0) * 0.25), _ab);
    // --- End Audio Reactivity ---

    color = vec4(finalColor, 1.0);
    color = xor_RGB(color, texture(samp, tc));
}
