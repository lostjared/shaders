#version 330 core

uniform float time_f;
uniform vec2 iResolution;
uniform sampler2D samp;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;
in vec2 tc;
out vec4 color;

vec4 xor_RGB(vec4 icolor, vec4 source) {
    ivec3 int_color;
    ivec4 isource = ivec4(source * 255);
    for(int i = 0; i < 3; ++i) {
        int_color[i] = int(255 * icolor[i]);
        int_color[i] = int_color[i] ^ isource[i];
        if(int_color[i] > 255)
            int_color[i] = int_color[i] % 255;
        icolor[i] = float(int_color[i]) / 255;
    }
    icolor.a = 1.0;
return icolor;
}

void main() {
    vec4 texColor = texture(samp, tc);
    float fluctuation = sin(time_f * (2.0 + amp_mid * 4.0)) * 0.5 + 0.5;
    vec3 extremeColor1 = vec3(1.0, 0.0, 0.0);
    vec3 extremeColor2 = vec3(0.0, 0.0, 1.0);
    vec3 fluctuatedColor = mix(extremeColor1, extremeColor2, fluctuation);
    vec4 fluctuatedVec = vec4(fluctuatedColor, 1.0);
    
    color = xor_RGB(texColor, fluctuatedVec);

    // --- Audio Reactivity: direct output modulation ---
    float _ab = clamp(amp_peak, 0.0, 1.0);
    float _abass = clamp(amp_low, 0.0, 1.0);
    color.rgb *= 1.0 + _ab * 0.6;
    color.rgb = mix(color.rgb, color.rgb * vec3(1.0 + _abass * 0.3, 1.0 - _abass * 0.15, 1.0 + clamp(amp_high, 0.0, 1.0) * 0.25), _ab);
    // --- End Audio Reactivity ---

}
