#version 120

#include "/lib/framebuffer.glsl"

uniform   sampler2D     colortex0;
uniform   sampler2D     colortex4;

varying   vec4          texcoord;

/* DRAWBUFFERS:012 */

void main() {
    vec4 transparents = texture2D(colortex4, texcoord.xy);
    vec3 colorOut = vec3(mix(texture2D(colortex0, texcoord.xy).rgb, transparents.rgb, transparents.a));
    
    //float brightness = dot(colorOut, vec3(0.2126, 0.7152, 0.0722));
    float brightness = colorOut.r + colorOut.g + colorOut.g;
    brightness /= 3.0;

    FragData0 = vec4(colorOut, 1.0);
    FragData1 = mix(vec4(vec3(0.0), 1.0), vec4(colorOut, 1.0), brightness);
    FragData2 = vec4(brightness);
}
