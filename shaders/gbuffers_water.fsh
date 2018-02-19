#version 120

#include "/lib/framebuffer.glsl"
#include "/lib/math.glsl"

#define   PARALLAX_SCALE                              0.1   // [0.1 0.2 0.3 0.4 0.5 0.75 1.0]

uniform   sampler2D     texture;
uniform   sampler2D     depthtex0;
uniform   sampler2D     gaux4;

uniform   mat4          gbufferProjectionInverse;
uniform   mat4          gbufferModelViewInverse;

uniform   float         frameTimeCounter;

varying   vec3          tintColor;
varying   vec3          normal;
varying   vec3          worldSpacePosition;
varying   vec3          toCameraInTangentSpace;

varying   vec4          texcoord;
varying   vec4          lmcoord;

varying   float         isWater;
varying   float         isTransparent;
varying   float         isNPortal;

vec2 parallaxMapping(in vec3 V, in vec2 T, out float parallaxHeight) {
   // determine optimal number of layers
   const float minLayers = 10.0;
   const float maxLayers = 15.0;
   float numLayers = mix(maxLayers, minLayers, abs(dot(vec3(0.0, 0.0, 1.0), V)));

   // height of each layer
   float layerHeight = 1.0 / numLayers;
   // current depth of the layer
   float curLayerHeight = 0;
   // shift of texture coordinates for each layer
   vec2 dtex = PARALLAX_SCALE * V.xy / V.z / numLayers;

   // current texture coordinates
   vec2 currentTextureCoords = T;

   // depth from heightmap
   float heightFromTexture = texture2D(gaux4, currentTextureCoords).r;

   // while point is above the surface
   while(heightFromTexture > curLayerHeight) 
   {
      // to the next layer
      curLayerHeight += layerHeight; 
      // shift of texture coordinates
      currentTextureCoords -= dtex;
      // new depth from heightmap
      heightFromTexture = texture2D(gaux4, currentTextureCoords).r;
   }

   ///////////////////////////////////////////////////////////

   // previous texture coordinates
   vec2 prevTCoords = currentTextureCoords;

   // heights for linear interpolation
   float nextH	= heightFromTexture - curLayerHeight;
   float prevH	= texture2D(gaux4, prevTCoords).r
                           - curLayerHeight + layerHeight;

   // proportions for linear interpolation
   float weight = nextH / (nextH - prevH);

   // interpolation of texture coordinates
   vec2 finalTexCoords = prevTCoords * weight + currentTextureCoords * (1.0-weight);

   // interpolation of depth values
   parallaxHeight = curLayerHeight + prevH * weight + nextH * (1.0 - weight);

   // return result
   return finalTexCoords;
}

void main() {
    // PARALLAX
        vec3 V = normalize(toCameraInTangentSpace);

        float parallaxHeight;
        vec2 T = parallaxMapping(V, texcoord.st, parallaxHeight);

    vec4 waterColor;

    if (isWater > 0.9) {
        waterColor = texture2D(texture, T);
        waterColor.rgb *= vec3(0.0, 0.375, 0.5625); //(0.0, 0.25, 0.375) * 1.5;

        float dist = length(worldSpacePosition);

        if (dist <= 1.5) {
            vec3 color = vec3(sin(frameTimeCounter * 7.5 - distance(T, worldSpacePosition.xz + 0.5)));
            waterColor.rgb = mix(waterColor.rgb * (color + 5.0), waterColor.rgb, dist / 1.5);
        }

    } else {
        waterColor = texture2D(texture, texcoord.st);
        waterColor.rgb *= tintColor;
    }    

    #ifdef CLAY
        waterColor.rgb = tintColor;
    #endif

    FragData4 = vec4(waterColor.rgb * 1.25, waterColor.a * 0.5 + 0.5);
    FragData1 = vec4(lmcoord.st / 16.0, 0.0, 1.0);
    FragData2 = vec4(normal * 0.5 + 0.5, 1.0);
}
