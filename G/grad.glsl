#version 330 core
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 xor_RGB(vec4 icolor, vec4 source) {
    // Convert to integer RGB values (0-255)
    ivec3 int_color = ivec3(icolor.rgb * 255.0);
    ivec3 isource = ivec3(source.rgb * 255.0);

    // Perform XOR operation and ensure values stay within 0-255
    for (int i = 0; i < 3; ++i) {
        int_color[i] = (int_color[i] ^ isource[i]) % 256;
    }

    // Convert back to normalized float RGB
    vec3 result_color = vec3(int_color) / 255.0;

    // Ensure a minimum brightness to avoid black output
    result_color = max(result_color, vec3(0.1)); // Minimum brightness of 0.1 per channel

    return vec4(result_color, 1.0); // Preserve original alpha
}

void main(void) {

    if(time_f == 0.0) {
        color = vec4(1, 1, 1, 1);
        return;
    }

    vec2 uv = tc;
    vec2 warp = uv + vec2(
        sin(uv.y * 10.0 + time_f) * 0.1,
        sin(uv.x * 10.0 + time_f) * 0.1
    );
    vec3 colorShift = vec3(
        0.5 * sin(time_f * 0.5) + 0.5,
        0.5 * sin(time_f * 0.7 + 2.0) + 0.5,
        0.5 * sin(time_f * 0.3 + 4.0) + 0.5
    );
    float feedback = rand(uv + time_f);
    vec2 feedbackUv = tc;
    float time_t = mod(time_f, 50);
    vec4 texColor = texture(samp, feedbackUv);
    vec3 finalColor = texColor.rgb + colorShift;
    color = vec4(finalColor, texColor.a);
    color = color * (0.5 + 0.5 * sin(texColor * time_t));
    color = xor_RGB(color, texColor);
    color.rgb = clamp(color.rgb, vec3(0.2), vec3(1.0));
    color.a = 1.0;
}
