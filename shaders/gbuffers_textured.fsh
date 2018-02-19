#version 120

#include "/lib/framebuffer.glsl"

uniform   sampler2D     texture;

varying   vec3          tintColor;
varying   vec3          normal;

varying   vec4          texcoord;
varying   vec4          lmcoord;

/* DRAWBUFFERS:012 */

void main() {
    vec4 color = texture2D(texture, texcoord.st);
    color.rgb *= tintColor;

    #ifdef CLAY
        color.rgb = tintColor;
    #endif

    FragData0 = color;
    FragData1 = vec4(lmcoord.st / 16.0, 0.0, 1.0);
    FragData2 = vec4(normal * 0.5 + 0.5, 1.0);
}
