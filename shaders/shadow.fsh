#version 120

#include "/lib/framebuffer.glsl"

uniform   sampler2D     tex;

varying   vec4          texcoord;
varying   vec4          color;

varying   float         isPlayer;
varying   float         isBeacon;
varying   float         isFire;
varying   float         isTransparent;

/* DRAWBUFFERS:0 */

void main() {
    vec4 fragColor = color * texture2D(tex, texcoord.st);// * texture2D(tex, texcoord.st).a;

    if (isBeacon > 0.9 || isFire > 0.9) {
        discard;
    }

    if (fragColor.a < 0.1) {
        discard;
    }

    fragColor = mix(vec4(0.0), fragColor, isTransparent);

    FragData0 = vec4(fragColor.rgb, 1.0);
}