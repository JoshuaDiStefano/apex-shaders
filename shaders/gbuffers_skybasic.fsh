#version 120

#include "/lib/framebuffer.glsl"

uniform   sampler2D     gcolor;

varying   vec3          tintColor;
varying   vec3          normal;

varying   vec4          texcoord;
varying   vec4          lmcoord;

/* DRAWBUFFERS:0 */

void main() {    
    FragData0 = vec4(1.0);
}
