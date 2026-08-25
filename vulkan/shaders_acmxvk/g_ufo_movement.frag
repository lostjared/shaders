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
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define iamp ext.u1.z
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;











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