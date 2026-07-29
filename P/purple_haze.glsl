#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

void main(void) {
    // Common parameters
    vec2 center = vec2(0.5);
    vec3 purpleTint = vec3(0.7, 0.0, 0.7); // Strong purple color

    // Wave 1: Diagonal Red Wave
    float ripple1 = sin(tc.x * 12.0 + time_f * 5.0) * 0.03;
    ripple1 += sin(tc.y * 9.6 + time_f * 6.0) * 0.03;
    vec2 tc1 = tc + vec2(ripple1);
    tc1.y += sin(time_f * 2.5) * 0.02; // Vertical movement
    
    // Spiral effect
    vec2 pos1 = tc1 - center;
    float angle1 = length(pos1) * 8.0 + time_f * 3.0;
    mat2 rot1 = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    tc1 = rot1 * pos1 + center;


    // Wave 2: Horizontal Blue Wave
    float ripple2 = sin(tc.x * 15.0 + time_f * 6.5) * 0.025;
    ripple2 += sin(tc.y * 4.5 + time_f * 4.5) * 0.025;
    vec2 tc2 = tc + vec2(ripple2 * 1.5, -ripple2 * 0.7);
    tc2.y += sin(time_f * 3.0) * 0.015; // Vertical movement
    
    // Reverse spiral
    vec2 pos2 = tc2 - center;
    float angle2 = -length(pos2) * 6.0 + time_f * 2.5;
    mat2 rot2 = mat2(cos(angle2), -sin(angle2), sin(angle2), cos(angle2));
    tc2 = rot2 * pos2 + center;

    // Wave 3: Vertical Combined Wave
    float ripple3 = sin(tc.x * 6.0 + time_f * 4.0) * 0.035;
    ripple3 += sin(tc.y * 14.0 + time_f * 5.2) * 0.035;
    vec2 tc3 = tc + vec2(ripple3 * 0.4, ripple3);
    tc3.y += sin(time_f * 4.5) * 0.025; // Vertical movement
    
    // Swirling spiral
    vec2 pos3 = tc3 - center;
    float angle3 = length(pos3) * 10.0 + time_f * 4.0;
    mat2 rot3 = mat2(cos(angle3), -sin(angle3), sin(angle3), cos(angle3));
    tc3 = rot3 * pos3 + center;

    // Sample texture with psychedelic combination
    vec3 c = vec3(0.0);
    c.r += texture(samp, tc1).r * 1.2;
    c.b += texture(samp, tc2).b * 1.2;
    c.rb += texture(samp, tc3).rb * 0.8;

    // Apply purple tint and boost intensity
    color = vec4(c * purpleTint * 1.5, 1.0);
    color = mix(color, texture(samp, tc), 0.5);
    color = vec4(color.rgb, texture(samp, tc).a);
}