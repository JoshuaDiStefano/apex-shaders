#version 120

const     float         sunPathRotation           = -22.5; // [-22.5 22.5]
const     float         shadowDistance            = 128.0;

const     int           shadowMapResolution       = 2048;  // [1024 2048 4096]
const     int           noiseTextureResolution    = 512;

#include "/lib/framebuffer.glsl"
#include "/lib/math.glsl"
#include "/lib/poisson.glsl"

#define TRANSPARENTS_SHADOWS

uniform   mat4          gbufferModelViewInverse;
uniform   mat4          gbufferProjectionInverse;

uniform   mat4          shadowModelView;
uniform   mat4          shadowProjection;

uniform   sampler2D     colortex1;
uniform   sampler2D     colortex2;
uniform   sampler2D     colortex4;
uniform   sampler2D     noisetex;
uniform   sampler2D     depthtex0;
uniform   sampler2D     gdepthtex;
uniform   sampler2D     shadow;
uniform   sampler2D     watershadow;
uniform   sampler2D     shadowtex0;
uniform   sampler2D     shadowtex1;
uniform   sampler2D     shadowcolor0;

uniform   vec3          upPosition;
uniform   vec3          cameraPosition;

uniform   float         viewHeight;
uniform   float         viewWidth;

varying   vec4          texcoord;

varying   vec3          lightVector;
varying   vec3          lightColor;
varying   vec3          skyColor;

varying   float         isNight;

vec4 getAlbedo(in vec2 coord) {
    return pow(texture2D(colortex4, coord), vec4(2.2));
}

vec4 getDepth(in vec2 coord) {
  return texture2D(gdepthtex, coord);
}

vec3 getNormal(in vec2 coord) {
    return texture2D(colortex2, coord).rgb * 2.0 - 1.0;
}

struct LightingParams {
    float Emission;
    float TorchLightStrength;
    float SkyLightStrength;
};

LightingParams getLightingParams(in vec2 coord) {
    LightingParams lp;

    vec3 ct1 = texture2D(colortex1, coord).rgb;

    lp.Emission = ct1.b;
    lp.TorchLightStrength = pow(ct1.r, 2.2);
    lp.SkyLightStrength = ct1.g;

    return lp;
}

/* DRAWBUFFERS:1234 */

vec4 getCameraSpacePositionShadow(in vec2 coord) {
    float depth = getDepth(coord).r;
    vec4 positionNdcSpace = vec4(coord.s * 2.0 - 1.0, coord.t * 2.0 - 1.0, 2.0 * depth - 1.0, 1.0);
    vec4 positionCameraSpace = gbufferProjectionInverse * positionNdcSpace;

    return positionCameraSpace / positionCameraSpace.w;
}

vec4 getWorldSpacePositionShadow(in vec2 coord) {
    vec4 positionCameraSpace = getCameraSpacePositionShadow(coord);
    vec4 positionWorldSpace = gbufferModelViewInverse * positionCameraSpace;
    positionWorldSpace.xyz += cameraPosition.xyz;

    return positionWorldSpace;
}

vec3 getShadowSpacePosition(in vec2 coord) {
    vec4 positionWorldSpace = getWorldSpacePositionShadow(coord);

    positionWorldSpace.xyz -= cameraPosition;
    vec4 positionShadowSpace = shadowModelView * positionWorldSpace;
    positionShadowSpace = shadowProjection * positionShadowSpace;
    positionShadowSpace /= positionShadowSpace.w;

    float dist = sqrt(positionShadowSpace.x * positionShadowSpace.x + positionShadowSpace.y * positionShadowSpace.y);
    float distortFactor = (1.0f - 0.85) + dist * 0.85;

    positionShadowSpace.xy *= 1.0f / distortFactor;

    return positionShadowSpace.xyz * 0.5 + 0.5;
}

mat2 getRotationMatrix(in vec2 coord) {
    float angle = texture2D(
        noisetex,
        coord * vec2(
            viewWidth / noiseTextureResolution,
            viewHeight / noiseTextureResolution
        )
    ).r * (2.0 * 3.1415);

    vec2 sc = vec2(sin(angle), cos(angle));
    return mat2(
        sc.y, -sc.x,
        sc.x, sc.y
    );
}

float getPenumbraWidth(in vec3 shadowCoord) {
    float dFragment = shadowCoord.z; //distance from pixel to light
    float dBlocker = 0.0; //distance from blocker to light
    float penumbra = 0.0;
    
    float shadowMapSample; //duh
    float numBlockers = 0.0;

    float searchSize = LIGHT_SIZE / dFragment;

    for (int x = -PCSS_SAMPLE_COUNT; x < PCSS_SAMPLE_COUNT; x++) {
        for (int y = -PCSS_SAMPLE_COUNT; y < PCSS_SAMPLE_COUNT; y++) {
            vec2 sampleCoord = shadowCoord.st + (vec2(x, y) * searchSize / (shadowMapResolution * 25 * PCSS_SAMPLE_COUNT));
            shadowMapSample = texture2D(shadowtex0, sampleCoord, 2.0).r;

            dBlocker += shadowMapSample;
            numBlockers += 1.0;
        }
    }

    if(numBlockers > 0.0) {
		dBlocker /= numBlockers;
		penumbra = (dFragment - dBlocker) * LIGHT_SIZE / dFragment;
	}

    return clamp(max(penumbra, MIN_PENUMBRA_SIZE), 0.0, 10.0);
}

vec3 getShadowColor(in vec2 coord) {
    vec3 shadowCoord = getShadowSpacePosition(coord);
    vec3 shadowColor = vec3(0.0);

    #ifdef PCSS
        float penumbraSize = getPenumbraWidth(shadowCoord);
    #else
        float penumbraSize = 0.5;
    #endif
    
    int numSamples = 64;

    float shadowMapBias;

    mat2 rotationMatrix = getRotationMatrix(coord);

    for (int i = 0; i < numSamples; i++) {
        vec2 offset = disc64[i] / shadowMapResolution;
        offset *= penumbraSize;
        #ifdef RANDOM_ROTATION
            offset = rotationMatrix * offset;
        #endif

        shadowMapBias = 0.0005 * (length(offset) + 0.75);

        vec2 adjustedShadowCoord = shadowCoord.st + offset;
        
        float shadowMapSample = texture2D(shadowtex1, adjustedShadowCoord).r;
        float visibility = step(shadowCoord.z - shadowMapSample, shadowMapBias);
        
        float shadowMapSampleTransparent = texture2D(watershadow, adjustedShadowCoord).r;
        float transparentVisibility = step(shadowCoord.z - shadowMapSampleTransparent, shadowMapBias);

        vec3 colorSample = texture2D(shadowcolor0, adjustedShadowCoord).rgb;

        colorSample = mix(colorSample, vec3(1.0), transparentVisibility);
        colorSample = mix(vec3(0.0), colorSample, visibility);

        shadowColor += colorSample;
    }

    shadowColor /= numSamples;

    return shadowColor * 0.111;
}

struct Fragment {
    vec4 albedo;
    vec3 normal;

    float emission;
};

struct Lightmap {
    float torchLightStrength;
    float skyLightStrength;
};

Fragment getFragment(in vec2 coord) {
    Fragment newFragment;

    LightingParams lp = getLightingParams(coord);

    newFragment.albedo = getAlbedo(coord);
    newFragment.normal = getNormal(coord);
    newFragment.emission = lp.Emission;

    return newFragment;
}

Lightmap getLightmapSample(in vec2 coord) {
    Lightmap lightmap;

    LightingParams lp = getLightingParams(coord);

    lightmap.torchLightStrength = lp.TorchLightStrength * 0.5;
    lightmap.skyLightStrength = lp.SkyLightStrength;

    return lightmap;
}

vec4 calculateLighting(in Fragment frag, in Lightmap lm, in vec2 coord) {
    float nDotL = dot(frag.normal, lightVector);
    float uDotL = dot(normalize(upPosition), lightVector);

    float directLightStrength = nDotL;
    directLightStrength = max(0.0, directLightStrength);
    vec3 directLight = directLightStrength * lightColor;

    vec3 torchColor = vec3(0.02125, 0.005, 0.00125);
    vec3 torchLight = torchColor * lm.torchLightStrength;

    vec3 skyLight = skyColor * lm.skyLightStrength;

    vec3 nonDirectLight = skyLight + torchLight;
    vec3 shadowColor;

    #ifdef TRANSPARENTS_SHADOWS
        shadowColor = getShadowColor(coord);
    #else
        shadowColor = vec3(0.1);
    #endif

    vec3 litColor = frag.albedo.rgb * (directLight * shadowColor + nonDirectLight);

    return vec4(litColor, frag.albedo.a);
}

void desat(inout vec3 color, in float strength) {			//Desaturates any color input at night, simulating the rods in the human eye

	float amount = 0.8f; 						//How much will the new desaturated and tinted image be mixed with the original image
	vec3 rodColor = vec3(0.2f, 0.4f, 1.0f); 	//Cyan color that humans percieve when viewing extremely low light levels via rod cells in the eye
	float colorDesat = dot(color, vec3(1.0f)); 	//Desaturated color

	color = mix(color, vec3(colorDesat) * rodColor, strength * amount);
    color *= 0.5;
	//color.rgb = color.rgb;
}

void main() {
    //vec4 worldPos = normalize(getWorldSpacePositionSky(texcoord.st));

    Fragment frag = getFragment(texcoord.st);
    Lightmap lm = getLightmapSample(texcoord.st);

    vec4 finalColor = calculateLighting(frag, lm, texcoord.st);
    //finalColor = texture2D(colortex4, texcoord.st).rgb;

    if (bool(isNight)) {
        desat(finalColor.rgb, 1.0 - clamp(lm.torchLightStrength, 0.0, 1.0));
    }

    //FragData0 = vec4(vec3(fract(worldPos.xz / worldPos.y), 0.0), 1.0);
    //FragData0 = vec4(texture2D(gdepthtex, texcoord.st).rgb, 1.0);
    //FragData0 = vec4(vec3((getCameraDepthBuffer(texcoord.st)) / 50.0), 1.0);
    FragData3 = finalColor;
}
