#version 120

#include "/lib/framebuffer.glsl"
#include "/lib/math.glsl"

//#define LOWPOLY_WATER

uniform   sampler2D     texture;
uniform   sampler2D     depthtex0;
uniform   sampler2D     gaux2;
uniform   sampler2D     specular;
uniform   sampler2D     normals;

uniform   vec3          cameraPosition;
uniform   vec3          previousCameraPosition;

uniform   float         frameTime;
uniform   float         frameTimeCounter;

varying   mat3          tbn;

varying   vec3          tintColor;
varying   vec3          normal;
varying   vec3          binormal;
varying   vec3          tangent;
varying   vec3          nnormal;
varying   vec3          headPosition;
varying   vec3          vertPosition;
varying   vec3          viewVector;
varying   vec3          worldpos;

varying   vec4          texcoord;
varying   vec4          lmcoord;

varying   float         isWater;
varying   float         isGlass;
varying   float         isTransparent;

/* DRAWBUFFERS:4125 */

void main() {
    vec4 waterColor = texture2D(texture, texcoord.st);

    vec3 normalMap;

    if (isWater > 0.9) {
        waterColor = vec4(vec3(0.0, 0.375, 0.5625), 0.75); //(0.0, 0.25, 0.375) * 1.5;

        float dist = length(headPosition);

        vec3 direction = cameraPosition - previousCameraPosition;
        float speed = length(direction) / frameTime;

        vec4 velocity = vec4(normalize(direction), speed);

        if (dist <= 1.62) {
            vec3 color = vec3(sin(frameTimeCounter * 7.5 - distance(texcoord.st, headPosition.xz + 0.5))) + velocity.w;
            //waterColor.rgb = mix(waterColor.rgb * (color + 5.0), waterColor.rgb, dist / 1.62);
        }

        vec3 posxz = worldpos.xyz;
        posxz.x += sin(posxz.z + frameTimeCounter) * 0.2;
        posxz.z += cos(posxz.x + frameTimeCounter * 0.5) * 0.2;

        float wave = 0.05 * sin(2 * pi * (frameTimeCounter + posxz.x  + posxz.z / 2.0))
                   + 0.05 * sin(2 * pi * (frameTimeCounter * 1.2 + posxz.x / 2.0 + posxz.z));
        
        vec3 newnormal = vec3(sin(wave * pi), 1.0 - cos(wave * pi), wave);

        vec3 bump = newnormal;
		
		float bumpmult = 0.1;	
		
		bump = bump * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0, 0.0, 1.0 - bumpmult);

        mat3 tbnMatrix = mat3(tangent.x, binormal.x, nnormal.x,
							  tangent.y, binormal.y, nnormal.y,
							  tangent.z, binormal.z, nnormal.z);

        vec3 N = normalize(cross(dFdx(vertPosition), dFdy(vertPosition)));

        // calculate tangent and bitangent
        vec3 P1 = dFdx(vertPosition);
        vec3 P2 = dFdy(vertPosition);
        vec2 Q1 = dFdx(texcoord.xy);
        vec2 Q2 = dFdy(texcoord.xy);
        
        vec3 T = normalize(P1 * Q2.t - P2 * Q1.t);
        vec3 B = normalize(P2 * Q1.s - P1 * Q2.s);

        // construct tangent space matrix and perturb normal
        mat3 TBN = mat3(T, B, normal);

        #ifdef LOWPOLY_WATER
            normalMap = normalize(normal * TBN);
        #else
            normalMap = normalize(bump * tbnMatrix);
        #endif

        FragData3 = vec4(0.925, 0.0, 0.0, 1.0);

    } else {
        waterColor.rgb *= tintColor;

        normalMap = texture2D(normals, texcoord.st).rgb;
        normalMap = normalMap * 2.0 - 1.0;
        normalMap = normalize(tbn * normalMap);

        if (isGlass > 0.9) {
            FragData3 = vec4(0.65);
        } else {
            FragData3 = texture2D(specular, texcoord.st);
        }
    }    

    #ifdef CLAY
        waterColor.rgb = tintColor;
    #endif

    FragData0 = waterColor;
    FragData1 = vec4(clamp(lmcoord.st / 256.0, vec2(0.0), vec2(1.0)), 0.0, 1.0);
    FragData2 = vec4(clamp(normalMap * 0.5 + 0.5, vec3(0.0), vec3(1.0)), 1.0);
}
