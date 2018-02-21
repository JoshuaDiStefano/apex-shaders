#version 120

#include "/lib/framebuffer.glsl"

uniform   sampler2D     gcolor;

varying   vec3          tintColor;
varying   vec3          normal;

varying   vec4          texcoord;
varying   vec4          lmcoord;

/* DRAWBUFFERS:0 */

void main() {
    //vec4 color = texture2D(gcolor, texcoord.st);
    vec4 color;
    color.rgb = tintColor;

    #ifdef CLAY
        color.rgb = tintColor;
    #endif
    
    FragData0 = vec4(color.rgb, 1.0);
}
