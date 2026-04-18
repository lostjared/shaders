#version 330 core

out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp_peak;
uniform sampler1D spectrum; // Our 1D frequency spectrum

// Helper matrices for 3D rotation
mat3 rotX(float a){float s=sin(a),c=cos(a);return mat3(1,0,0, 0,c,-s, 0,s,c);}
mat3 rotY(float a){float s=sin(a),c=cos(a);return mat3(c,0,s, 0,1,0, -s,0,c);}
mat3 rotZ(float a){float s=sin(a),c=cos(a);return mat3(c,-s,0, s,c,0, 0,0,1);}

void main(void){
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    // 1. Audio Sampling
    float sBass   = texture(spectrum, 0.02).r; 
    float sMid    = texture(spectrum, 0.25).r;
    float sTreble = texture(spectrum, 0.75).r;

    // 2. 3D Space Projection
    vec2 p = (tc - m) * ar;
    vec3 v = vec3(p, 1.0);
    float ax = 0.25 * sin(time_f * 0.7);
    float ay = 0.25 * cos(time_f * 0.6);
    float az = 0.4 * time_f + (sBass * 0.5); // Bass rotates the web
    mat3 R = rotZ(az) * rotY(ay) * rotX(ax);
    vec3 r = R * v;
    
    float persp = 0.6;
    float zf = 1.0 / (1.0 + r.z * persp);
    vec2 q = r.xy * zf;

    // 3. Log-Polar Fractal "Spinning"
    float eps = 1e-6;
    float base = 1.72;
    float period = log(base);
    float t = time_f * 0.5;
    float rad = length(q) + eps;
    float ang = atan(q.y, q.x) + t * 0.3;
    
    // The "Tunnel" math
    float k = fract((log(rad) - t) / period);
    float rw = exp(k * period);
    vec2 qwrap = vec2(cos(ang), sin(ang)) * rw;

    // 4. Kaleidoscope Web Geometry
    // N segments for the radial "spokes" of the web
    float N = 8.0 + floor(sMid * 8.0); 
    float stepA = 6.28318530718 / N;
    float a = atan(qwrap.y, qwrap.x) + time_f * 0.05;
    float web_ang = mod(a, stepA);
    web_ang = abs(web_ang - stepA * 0.5);
    vec2 kdir = vec2(cos(web_ang), sin(web_ang));
    vec2 kaleido = kdir * length(qwrap);

    // 5. Drawing the Silk (Filaments)
    // We create thin lines based on the radial angle and concentric distance
    float radial_silk = smoothstep(0.03, 0.0, abs(web_ang));
    float ring_silk   = smoothstep(0.05, 0.0, abs(fract(log(rad) * 2.0 + sBass) - 0.5));
    float web_mask    = max(radial_silk, ring_silk);

    // 6. Final Texture Mapping & Neon Glow
    vec2 uv = fract(kaleido / ar + m);
    vec3 tex = texture(samp, uv).rgb;
    
    // Add glowing "spider silk" color
    vec3 silk_color = vec3(0.5, 0.8, 1.0) * sTreble * 5.0; 
    vec3 final_rgb = mix(tex, silk_color, web_mask * sMid);

    // Flash the web into negative energy on peaks
    if (amp_peak > 0.98) final_rgb = 1.0 - final_rgb;

    color = vec4(final_rgb, 1.0);
}