#version 330 core

out vec4 color;
in vec2 tc;
uniform sampler2D samp;

void main(void) {
    vec3 col = texture(samp, tc).rgb;
    
    if(col.r < 0.3 && col.g < 0.3 && col.b < 0.3)
        color = vec4(1.0, 0.0, 0.0, 1.0);
    else
        color = vec4(col, 1.0);
     
 }