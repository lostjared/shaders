#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;

uniform float amp_peak; 
uniform float amp_rms; 
uniform float amp_smooth; 
uniform float amp_low; 
uniform float amp_mid; 
uniform float amp_high; 
uniform float iamp; 

mat3 rotX(float a){float s=sin(a),c=cos(a);return mat3(1,0,0, 0,c,-s, 0,s,c);}
mat3 rotY(float a){float s=sin(a),c=cos(a);return mat3(c,0,s, 0,1,0, -s,0,c);}
mat3 rotZ(float a){float s=sin(a),c=cos(a);return mat3(c,-s,0, s,c,0, 0,0,1);}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    vec2 p2 = (tc - m) * ar;
    
    // Base 3D wobbly projection
    float ax = 0.25 * sin(time_f * 0.7);
    float ay = 0.25 * cos(time_f * 0.6);
    float az = time_f * 0.5;
    vec3 p3 = vec3(p2, 1.0);
    
    mat3 R = rotZ(az) * rotY(ay) * rotX(ax);
    vec3 r = (R * (1.0 + amp_smooth * 0.2)) * p3;
				
    float k = 0.6;
    float zf = 1.0 / (1.0 + r.z * k);
    vec2 q = r.xy * zf;

    /**
     * @brief Audio-reactive rotation
     * Applies a 2D rotation matrix to the projected coordinates.
     * - amp_low : Drives the spin angle (kicks on bass)
     * - amp_mid/high : Drives the scale (pumping effect)
     */
    
    // Calculate rotation angle (baseline time + bass kicks)
    float angle = (time_f * 0.5) + (amp_low * 3.0);
    
    // 2D Rotation matrix
    float s = sin(angle);
    float c = cos(angle);
    mat2 rot2D = mat2(c, -s, 
                      s,  c);
                      
    // Apply rotation
    q = rot2D * q;

    // Apply audio-driven scaling
    float scale = 1.0 - (amp_mid * 0.2) + (amp_high * 0.1);
    q *= scale;

    // Convert back to UV space
    vec2 uv = q / ar + m;
    uv = clamp(uv, 0.0, 1.0);
    
    color = texture(samp, uv);
}