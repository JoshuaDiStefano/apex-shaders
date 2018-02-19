#version 120

#include "/lib/framebuffer.glsl"
#include "/lib/poisson.glsl"

uniform   sampler2D     colortex0;
uniform   sampler2D     colortex1;
uniform   sampler2D     colortex2;

const     float         sunPathRotation           = -22.5;
const     float         shadowDistance            = 128.0;

const     int           shadowMapResolution       = 4096;   // [1024 2048 4096]
const     int           noiseTextureResolution    = 512;

#define   BAD_SKY
#define   RANDOM_ROTATION
#define   RANDOM_ROTATION_FILTER

#define   PCF_SAMPLE_COUNT                            2     // [1 2 3 4 5]
#define   PCSS_SAMPLE_COUNT                           3     // [1 2 3 4 5]
#define   MIN_PENUMBRA_SIZE                           0.25  // [0.0 0.1 0.25 0.5]
#define   LIGHT_SIZE                                  100   // [100 125 150]
#define   PCSS

uniform   int           worldTime;

uniform   vec3          upPosition;
uniform   vec3          cameraPosition;

uniform   sampler2D     noisetex;
uniform   sampler2D     depthtex0;
uniform   sampler2D     gdepthtex;
uniform   sampler2D     shadow;
uniform   sampler2D     shadowtex0;
uniform   sampler2D     shadowcolor0;
uniform   sampler2D     colortex4;

uniform   mat4          gbufferProjectionInverse;
uniform   mat4          gbufferModelViewInverse;

uniform   mat4          shadowModelView;
uniform   mat4          shadowProjection;

uniform   float         viewHeight;
uniform   float         viewWidth;

varying   vec4          texcoord;

varying   vec3          lightVector;
varying   vec3          lightColor;
varying   vec3          skyColor;

varying   float         isNight;

vec3 getAlbedo(in vec2 coord) {
    return pow(texture2D(colortex0, coord).rgb, vec3(2.2));
    //return vec3(1.0, 1.0, 1.0);
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

/* DRAWBUFFERS:01234 */

vec4 getCameraSpacePositionSky(in vec2 coord) {
  float depth = getDepth(coord).r;
  vec4 positionNdcSpace = vec4(coord.s * 2.0 - 1.0, coord.t * 2.0 - 1.0, 2.0 * depth - 1.0, 1.0);
  vec4 positionCameraSpace = normalize(gbufferProjectionInverse * positionNdcSpace);
  
  return positionCameraSpace / positionCameraSpace.w;
}

vec4 getWorldSpacePositionSky(in vec2 coord) {
    vec4 tmp = gbufferProjectionInverse * vec4(coord * 2.0 - 1.0, 1.0, 1.0);
    vec3 viewPos = tmp.xyz / tmp.w;
    vec4 positionCameraSpace = vec4(viewPos, 1.0);
    vec4 positionWorldSpace = gbufferModelViewInverse * vec4(positionCameraSpace);
    //positionWorldSpace.xyz *= cameraPosition.xyz;

    return positionWorldSpace;
}

float getCameraDepthBuffer(in vec2 coord) {
    vec3 pos = vec3(coord, texture2D(depthtex0, coord).r);
    vec4 v = gbufferProjectionInverse * vec4(pos * 2.0 - 1.0, 1.0);
    return length(pos) / v.w;
}

vec3 calcSky(in vec2 coord) {
    vec3 worldPos = getWorldSpacePositionSky(coord).xyz;

    vec3 tmp2 = normalize(worldPos);
    vec2 noisePos = tmp2.xz / tmp2.y;

    vec3 view = normalize(getCameraSpacePositionSky(coord).xyz);
    vec3 up = normalize(upPosition);
    vec3 noise = texture2D(noisetex, noisePos).rgb;
    
    vec3 baseColor;
    vec3 baseColorBad;
    
    float distToHorizon = max(0.0, dot(view, up));    
    float timeInfluence = max(dot(view, lightVector), 0.0);

    bool isStar = bool(float(noise.b > 0.985 || noise.r > 0.985));

    if (isStar && isNight == 1.0) {
        baseColor = vec3(1.0);
        baseColorBad = vec3(1.0) * (1.0 - timeInfluence);
    } else {
        vec3 horizonColorDay = vec3(0.75, 1.25, 2.0) * 65.0;
        vec3 zenithColorDay = vec3(0.15, 0.75, 1.5) * 0.5;
        vec3 haloColorDay = vec3(1.0, 1.0, 0.9) * 1.5;

        vec3 horizonColorNight = vec3(0.15, 0.5, 1.0);
        vec3 zenithColorNight = vec3(0.0);
        vec3 haloColorNight = vec3(1.0);

        vec3 dayColor = mix(horizonColorDay, mix(zenithColorDay, haloColorDay, pow(timeInfluence, 400.0) * 2.0), distToHorizon + (1.0 - distToHorizon) / 1.01);
        vec3 nightColor = mix(zenithColorNight, haloColorNight, pow(timeInfluence, 1000.0) * 2.0);
        vec3 sunColor = vec3(0.9, 0.9, 0.4) * 5.0;
        vec3 moonColor = vec3(1.0) * 3.0;

        vec3 skyColor = mix(dayColor, nightColor, -timeInfluence);
    
        if (timeInfluence > 0.0) {
            baseColorBad = dayColor;
        } else {
            baseColorBad = nightColor;
        }

        if (timeInfluence > mix(0.999, 0.998, isNight)) {
            baseColor = mix(sunColor, moonColor, isNight);
        } else {
            baseColor = mix(dayColor, nightColor, isNight);
        }
    }
    
    #ifdef BAD_SKY
        return baseColorBad;
    #else
        return baseColor;
    #endif
}

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
            vec2 sampleCoord = shadowCoord.st + (vec2(x, y) * searchSize / (shadowMapResolution * 5 * PCSS_SAMPLE_COUNT));
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

    #ifdef PCSS
        float penumbraSize = getPenumbraWidth(shadowCoord);
    #else
        float penumbraSize = 0.5;
    #endif

    float numSamples = 0.0;

    vec3 shadowColor = vec3(0.0);

    mat2 rotationMatrix = getRotationMatrix(coord);
    
    float shadowMapBias;

    for (int i = 0; i < 64; i++) {
        vec2 offset = disc64[i] / shadowMapResolution;
        offset *= penumbraSize;
        #ifdef RANDOM_ROTATION
            offset = rotationMatrix * offset;
        #endif

        shadowMapBias = 0.0005 * (length(offset) + 0.75);

        vec2 adjustedShadowCoord = shadowCoord.st + offset;
        
        float shadowMapSample = texture2D(shadow, adjustedShadowCoord).r;
        float visibility = step(shadowCoord.z - shadowMapSample, shadowMapBias);

        vec3 colorSample = texture2D(shadowcolor0, adjustedShadowCoord).rgb;
        shadowColor += mix(colorSample, vec3(1.0), visibility);

        numSamples++;
    }

    shadowColor /= numSamples;

    return shadowColor * 0.111;
}

struct Fragment {
    vec3 albedo;
    vec4 albedo1;
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

    lightmap.torchLightStrength = lp.TorchLightStrength;
    lightmap.skyLightStrength = lp.SkyLightStrength;

    return lightmap;
}

vec3 calculateLighting(in Fragment frag, in Lightmap lm, in vec2 coord) {
    float nDotL = dot(frag.normal, lightVector);
    float uDotL = dot(normalize(upPosition), lightVector);  

    float directLightStrength = max(0.0, nDotL);
    vec3 directLight = directLightStrength * lightColor;

    vec3 torchColor = vec3(0.85, 0.2, 0.05) * 0.025;
    vec3 torchLight = torchColor * lm.torchLightStrength;
    vec3 skyLight = skyColor * lm.skyLightStrength;

    vec3 shadowColor = getShadowColor(coord);
    vec3 nonDirectLight = skyLight + torchLight;
    vec3 litColor = frag.albedo * (directLight * shadowColor + nonDirectLight);

    return mix(litColor, frag.albedo * (uDotL * lightColor * shadowColor + nonDirectLight), frag.emission);
}

void main() {
    //vec4 worldPos = normalize(getWorldSpacePositionSky(texcoord.st));

    Fragment frag = getFragment(texcoord.st);
    Lightmap lm = getLightmapSample(texcoord.st);

    vec3 finalColor;

    if (texture2D(depthtex0, texcoord.st) == vec4(1.0)) {
        finalColor = calcSky(texcoord.st);
        //finalColor = vec3(fract(worldPos.xz), 0.0);
        //finalColor = texture2D(noisetex, worldPos.xz / worldPos.y).rgb;
    } else {
        finalColor = calculateLighting(frag, lm, texcoord.st);
    }
        /*else if (texture2D(colortex4, texcoord.st).r == 1.0) {
        finalColor = texture2D(colortex4, texcoord.st).rgb;
        //finalColor += calculateLighting(frag, lm, texcoord.st);
    } else {
        finalColor = calculateLighting(frag, lm, texcoord.st);
    }*/

    //finalColor = texture2D(colortex4, texcoord.st).rgb;

    //FragData0 = vec4(vec3(fract(worldPos.xz / worldPos.y), 0.0), 1.0);
    //FragData0 = vec4(texture2D(gdepthtex, texcoord.st).rgb, 1.0);
    //FragData0 = vec4(vec3((getCameraDepthBuffer(texcoord.st)) / 50.0), 1.0);
    FragData0 = vec4(finalColor, 1.0);
    FragData4 = vec4(0.0);
}