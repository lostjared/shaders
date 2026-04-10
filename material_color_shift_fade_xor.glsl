#version 330
in vec2 tc;
out vec4 color;
uniform float alpha_r;
uniform float alpha_g;
uniform float alpha_b;
in float timeval;
uniform float alpha;
uniform vec4 optx;
uniform vec4 random_var;
uniform float alpha_value;
uniform mat4 mv_matrix;
uniform mat4 proj_matrix;
uniform sampler2D samp;
uniform sampler2D mat_samp;
uniform vec2 mat_size;
uniform vec4 inc_valuex;
uniform float value_alpha_r, value_alpha_g, value_alpha_b;
uniform float index_value;
uniform float time_f;
in vec2 iResolution_;
uniform vec2 iResolution;
uniform float restore_black;

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

vec4 xor_RGB(vec4 icolor, ivec4 isource) {
    ivec3 int_color;
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

void main(void)
{
    color = texture(samp, tc);
    ivec4 source = ivec4(color * 255);
    
    vec4 color2 = texture(samp, tc);
    vec4 color_mat = texture(mat_samp, tc);
    vec2 st = (gl_FragCoord.xy / iResolution_.xy);
    float rnd = random(st);
    vec4 v = vec4(fract(inc_valuex.x/3), fract(inc_valuex.y/9)*0.5, fract(inc_valuex.z/3), 1);
    v *= 0.5;
    vec4 color1 = v * vec4(1, st*fract(timeval/alpha)*6.0, 1);
    
    color = color * color1 * 4.0;
    color = (0.5 * color) + (0.5 * color_mat);
    color = xor_RGB(color, source);
}

