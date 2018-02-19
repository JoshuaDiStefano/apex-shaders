#version 120

#include "/lib/framebuffer.glsl"

uniform   sampler2D     texture;
uniform   sampler2D     normals;
uniform   sampler2D     noisetex;

varying   vec3          tintColor;
varying   vec3          normalOut;
varying   vec3          pos;

varying   vec4          texcoord;
varying   vec4          lmcoord;

varying   float         isEmissive;
varying   float         isFire;
varying   float         isLava;

/* DRAWBUFFERS:012 */

void main() {
    vec4 blockColor = texture2D(texture, texcoord.st);

    #ifdef CLAY
        blockColor.rgb = vec3(tintColor.g);
    #else
        blockColor.rgb *= tintColor;
    #endif
    
    if (isFire == 0.0) {
        FragData0 = blockColor;
    } else {
        FragData0 = blockColor;
        //FragData0 = vec4(1.0);
    }

    FragData1 = vec4(lmcoord.st / 16.0, isEmissive, 1.0);
    FragData2 = vec4(normalOut * 0.5 + 0.5, 1.0);
}