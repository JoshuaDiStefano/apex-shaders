#version 120

#include "/lib/framebuffer.glsl"

uniform   sampler2D     texture;

varying   vec3          tintColor;
varying   vec3          normal;

varying   vec4          texcoord;
varying   vec4          lmcoord;

/* DRAWBUFFERS:012 */

void main() {
    vec4 handColor = texture2D(texture, texcoord.st);
    handColor.rgb *= tintColor;

    #ifdef CLAY
        handColor.rgb = tintColor;
    #endif

    FragData0 = handColor;
    FragData1 = vec4(lmcoord.st / 256.0, 0.0, 1.0);
    FragData2 = vec4(normal * 0.5 + 0.5, 1.0);
}
