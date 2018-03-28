#version 120

#include "/lib/framebuffer.glsl"
#include "/lib/poisson.glsl"

uniform   sampler2D     colortex0;
uniform   sampler2D     colortex1;
uniform   sampler2D     colortex2;

const     float         sunPathRotation           = -22.5; // [-22.5 22.5]
const     float         shadowDistance            = 128.0;

const     int           shadowMapResolution       = 2048;  // [1024 2048 4096]
const     int           noiseTextureResolution    = 512;

//#define   BAD_SKY

uniform   int           worldTime;

uniform   vec3          upPosition;
uniform   vec3          cameraPosition;
uniform   vec3          sunPosition;

uniform   sampler2D     noisetex;
uniform   sampler2D     depthtex0;
uniform   sampler2D     gdepthtex;
uniform   sampler2D     shadow;
uniform   sampler2D     watershadow;
uniform   sampler2D     shadowtex0;
uniform   sampler2D     shadowtex1;
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
    vec3 view = normalize(getCameraSpacePositionSky(coord).xyz);
    vec3 up = normalize(upPosition);
    
    float distFromZenith = dot(view, up);
    float distToHorizon = max(0.0, distFromZenith);
    float sunInfluence = max(dot(view, normalize(sunPosition)), 0.0);
    float moonInfluence = max(dot(view, normalize(-sunPosition)), 0.0);
    float timeFactor = dot(lightVector, up);

    vec3 skyColor;

    vec3 horizonColorBottomNoon = vec3(0.3, 0.75, 1.0) * 5.0;
    vec3 horizonColorTopNoon = vec3(0.01, 0.2, 1.0) * 5.0 + 0.25;
    vec3 zenithColorNoon = vec3(0.01, 0.2, 1.0) * 5.0;

    vec3 horizonColorBottomMorning = vec3(0.9, 0.05, 0.0) * 0.1;
    vec3 horizonColorTopMorning = vec3(0.1, 0.2, 0.5) * 0.1;
    vec3 zenithColorMorning = vec3(0.01, 0.2, 1.0) * 0.01;

    vec3 haloColorNoon = vec3(1.0, 1.0, 0.9) * 5.0;
    vec3 sunColorNoon = vec3(1.0, 1.0, 0.5) * 15.0;

    vec3 haloColorMorning = vec3(1.0, 0.05, 0.0) * 5.0;
    vec3 sunColorMorning = vec3(1.0, 0.05, 0.0) * 10.0;

    vec3 haloColorNight = vec3(10.0);
    vec3 moonColor = vec3(10.0);

    vec3 black = vec3(0.0);

    float fallOff = mix(0.1, 0.35, timeFactor);

    float timeFallOffDay = 0.5;
    float timeFallOffNight = 0.15;

    float distanceCoeff = 1.0 / (1.0 - fallOff);

    vec3 horizonColorBottomFinal;
    vec3 horizonColorTopFinal;
    vec3 zenithColorFinal;

    vec3 haloColorDay;
    vec3 sunColorFinal;

    float factorMainDay = smoothstep(0.0, 1.0, timeFactor / timeFallOffDay);
    float factorMainNight = smoothstep(0.0, 1.0, timeFactor / timeFallOffNight);

    if (isNight < 0.9) {
        if (timeFactor <= timeFallOffDay) {
            horizonColorBottomFinal = mix(horizonColorBottomMorning, horizonColorBottomNoon, smoothstep(0.0, 2.5, timeFactor / timeFallOffDay));
            horizonColorTopFinal = mix(horizonColorTopMorning, horizonColorTopNoon, smoothstep(0.0, 0.75, timeFactor / timeFallOffDay));
            zenithColorFinal = mix(zenithColorMorning, zenithColorNoon, smoothstep(0.0, 2.0, timeFactor / timeFallOffDay));

            haloColorDay = mix(haloColorMorning, haloColorNoon, factorMainDay);
            sunColorFinal = mix(sunColorMorning, sunColorNoon, factorMainDay);
        } else {
            horizonColorBottomFinal = horizonColorBottomNoon;
            horizonColorTopFinal = horizonColorTopNoon;
            zenithColorFinal = zenithColorNoon;

            haloColorDay = haloColorNoon;
            sunColorFinal = sunColorNoon;
        }
    } else {
        if (timeFactor <= timeFallOffNight) {
            horizonColorBottomFinal = mix(horizonColorBottomMorning, black, factorMainNight);
            horizonColorTopFinal = mix(horizonColorTopMorning, black, factorMainNight);
            zenithColorFinal = mix(zenithColorMorning, black, factorMainNight);

            haloColorDay = mix(haloColorMorning, black, factorMainNight);
            sunColorFinal = mix(sunColorMorning, black, factorMainNight);
        } else {
            horizonColorBottomFinal = black;
            horizonColorTopFinal = black;
            zenithColorFinal = black;

            haloColorDay = black;
            sunColorFinal = black;
        }
    }

    if (distToHorizon < fallOff) {
        skyColor = mix(horizonColorBottomFinal, horizonColorTopFinal, smoothstep(0.0, 1.0, distToHorizon / fallOff));
    } else {
        skyColor = mix(horizonColorTopFinal, zenithColorFinal, smoothstep(0.0, 1.0, distToHorizon * distanceCoeff - (distanceCoeff - 1.0)));
    }

    skyColor += mix(skyColor, haloColorDay, pow(sunInfluence, 1000.0) * 2.0);
    skyColor += mix(skyColor, haloColorNight, pow(moonInfluence, 3000.0) * 2.0);

    if (sunInfluence > 0.999) {
        skyColor = sunColorFinal;
    }

    if (moonInfluence > 0.999) {
        skyColor = moonColor;
    }

    return skyColor;
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

vec3 calculateLighting(in Fragment frag, in Lightmap lm, in vec2 coord, in bool isSky) {
    if (!isSky) {
        float nDotL = dot(frag.normal, lightVector);
        float uDotL = dot(normalize(upPosition), lightVector);  

        float directLightStrength = max(0.0, mix(nDotL, uDotL, frag.emission));

        vec3 directLight = directLightStrength * lightColor;

        vec3 skyLight = skyColor * lm.skyLightStrength;

        vec3 torchColor = vec3(0.85, 0.2, 0.05) * 0.025;
        vec3 torchLight = torchColor * lm.torchLightStrength;

        vec3 nonDirectLight = skyLight + torchLight + 0.01;

        vec3 shadowColor = getShadowColor(coord);

        vec3 litColor = frag.albedo * (directLight * shadowColor + nonDirectLight);

        return litColor;
    } else {
        return frag.albedo;
    }
}

void desat(inout vec3 color, in float strengthCoeff) {

	float strength = 0.8f;
	vec3 rodColor = vec3(0.2f, 0.4f, 1.0f);
	float gray = dot(color, vec3(1.0f));

	color = mix(color, vec3(gray) * rodColor, strengthCoeff * strength);
    color *= 0.5;
	//color.rgb = color.rgb;
}

void main() {
    //vec4 worldPos = normalize(getWorldSpacePositionSky(texcoord.st));

    Fragment frag = getFragment(texcoord.st);
    Lightmap lm = getLightmapSample(texcoord.st);

    vec3 finalColor;

    if (texture2D(depthtex0, texcoord.st) == vec4(1.0)) {
        finalColor = calcSky(texcoord.st);
        
        //finalColor = calculateLighting(frag, lm, texcoord.st, true);
        //finalColor = vec3(fract(worldPos.xz), 0.0);
        //finalColor = texture2D(noisetex, worldPos.xz / worldPos.y).rgb;
    } else {
        finalColor = calculateLighting(frag, lm, texcoord.st, false);
    }

    if (bool(isNight)) {
        desat(finalColor.rgb, 1.0 - clamp(lm.torchLightStrength, 0.0, 1.0));
    }

    //FragData0 = vec4(vec3(fract(worldPos.xz / worldPos.y), 0.0), 1.0);
    //FragData0 = vec4(texture2D(gdepthtex, texcoord.st).rgb, 1.0);
    //FragData0 = vec4(vec3((getCameraDepthBuffer(texcoord.st)) / 50.0), 1.0);
    FragData0 = vec4(finalColor, 1.0);
    FragData4 = vec4(0.0);
}
