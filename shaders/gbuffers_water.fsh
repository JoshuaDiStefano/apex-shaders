#version 120

#include "/lib/framebuffer.glsl"
#include "/lib/math.glsl"

uniform   sampler2D     texture;
uniform   sampler2D     depthtex0;
uniform   sampler2D     gaux2;

uniform   mat4          gbufferProjectionInverse;
uniform   mat4          gbufferModelViewInverse;

uniform   float         frameTimeCounter;

varying   vec3          tintColor;
varying   vec3          normal;
varying   vec3          headPosition;

varying   vec4          texcoord;
varying   vec4          lmcoord;

varying   float         isWater;
varying   float         isTransparent;
varying   float         isNPortal;

void main() {
    vec4 waterColor = texture2D(texture, texcoord.st);

    if (isWater > 0.9) {
        waterColor.rgb *= vec3(0.0, 0.375, 0.5625); //(0.0, 0.25, 0.375) * 1.5;

        float dist = length(headPosition);

        if (dist <= 1.62) {
            vec3 color = vec3(sin(frameTimeCounter * 7.5 - distance(texcoord.st, headPosition.xz + 0.5)));
            waterColor.rgb = mix(waterColor.rgb * (color + 5.0), waterColor.rgb, dist / 1.62);
        }

    } else {
        waterColor.rgb *= tintColor;
    }    

    #ifdef CLAY
        waterColor.rgb = tintColor;
    #endif

    FragData4 = vec4(waterColor.rgb, waterColor.a * 0.5 + 0.5);
    FragData1 = vec4(lmcoord.st / 16.0, 0.0, 1.0);
    FragData2 = vec4(normal * 0.5 + 0.5, 1.0);
}
