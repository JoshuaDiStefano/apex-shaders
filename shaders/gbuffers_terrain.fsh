#version 120

#include "/lib/framebuffer.glsl"

uniform   sampler2D     texture;
uniform   sampler2D     specular;
uniform   sampler2D     normals;

varying   mat3          tbn;

varying   vec3          tintColor;
varying   vec3          normal;

varying   vec4          texcoord;
varying   vec4          lmcoord;

varying   float         isEmissive;
varying   float         isFire;
varying   float         isLava;

/* DRAWBUFFERS:01254 */

void main() {
    vec4 blockColor = texture2D(texture, texcoord.st);

    #ifdef CLAY
        blockColor.rgb = vec3(tintColor.g);
    #else
        blockColor.rgb *= tintColor;
    #endif

    vec2 lm = lmcoord.st / 256.0;

    vec3 normalMap = texture2D(normals, texcoord.st).rgb;
    normalMap = normalMap * 2.0 - 1.0;
    normalMap = normalize(tbn * normalMap);

    float specOut = texture2D(specular, texcoord.st).r;

    FragData0 = blockColor;
    FragData1 = vec4(clamp(lm, vec2(0.0), vec2(1.0)), isEmissive, 1.0);
    FragData2 = vec4(clamp(normalMap * 0.5 + 0.5, vec3(0.0), vec3(1.0)), 1.0);
    FragData3 = vec4(1.0, 1.0 - specOut, 0.0, 1.0);
    FragData4 = vec4(0.0);
}
