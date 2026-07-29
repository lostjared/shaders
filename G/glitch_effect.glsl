#version 330
in vec2 tc;
out vec4 color;
uniform float alpha_r;
uniform float alpha_g;
uniform float alpha_b;
uniform float alpha;
uniform vec4 optx;
in vec4 random_value;
uniform vec4 random_var;
uniform float alpha_value;
uniform mat4 mv_matrix;
uniform mat4 proj_matrix;
uniform sampler2D samp;
uniform float value_alpha_r, value_alpha_g, value_alpha_b;
uniform float index_value;
uniform float time_f;
uniform vec2 iResolution;

uniform float restore_black;
uniform vec4 inc_valuex;
uniform vec4 inc_value;

void main(void)
{
    float time = time_f * 0.2;
    vec2 glitchOffset = vec2(sin(time * 2.0) * 0.005, cos(time * 3.0) * 0.005);
    glitchOffset += vec2(random_value.x * 0.005, random_value.y * 0.005);
    
    vec2 tcOffset = tc + glitchOffset;
    
    vec4 baseColor = texture(samp, tcOffset);
    vec4 glitchColor = texture(samp, tc + glitchOffset * 2.0);
    
    color = mix(baseColor, glitchColor, 0.5);
    color.rgb *= vec3(1.0 + sin(time_f * 5.0) * 0.1, 1.0 + cos(time_f * 5.0) * 0.1, 1.0 + sin(time_f * 7.0) * 0.1);
}
