#version 120

#include "/lib/framebuffer.glsl"
#include "/lib/poisson.glsl"
#include "/lib/math.glsl"

//#define MC_GL_ARB_shader_texture_lod

#define rayleighCoeff (vec3(0.27, 0.5, 1.0) * 1e-5)
#define mieCoeff vec3(0.5e-6)

#define   VANILLA_SUN
#define   VANILLA_MOON

uniform   sampler2D     colortex0;
uniform   sampler2D     colortex1;
uniform   sampler2D     colortex2;
uniform   sampler2D     colortex3;
uniform   sampler2D     colortex4;
uniform   sampler2D     colortex5;
uniform   sampler2D     colortex6;
uniform   sampler2D     colortex7;

const     float         shadowDistance            = 256.0; // [128 256 512]

const     int           shadowMapResolution       = 2048;  // [1024 2048 4096]
const     int           noiseTextureResolution    = 512;

//#define   BAD_SKY

uniform   vec3          upPosition;
uniform   vec3          cameraPosition;
uniform   vec3          sunPosition;
uniform   vec3          fogColor;

uniform   sampler2D     noisetex;
uniform   sampler2D     depthtex0;
uniform   sampler2D     depthtex1;
uniform   sampler2D     gdepthtex;
uniform   sampler2D     shadow;
uniform   sampler2D     watershadow;
uniform   sampler2D     shadowtex0;
uniform   sampler2D     shadowtex1;
uniform   sampler2D     shadowcolor0;

uniform   mat4          gbufferProjectionInverse;
uniform   mat4          gbufferModelViewInverse;

uniform   mat4          shadowModelView;
uniform   mat4          shadowProjection;

uniform   float         viewHeight;
uniform   float         viewWidth;
uniform   float         rainStrength;
uniform   float         far;
uniform   float         near;
uniform   float         fogDensity;
uniform   float         frameTimeCounter;
uniform   float         sunAngle;
uniform   float         nightVision;

uniform   int           isEyeInWater;
uniform   int           worldTime;
uniform   int           shadowMapResInverse;

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

float generateStars(vec3 worldVector) { //          CREDIT TO ROBOBO1221 - Used with permission
    const float res = 200.0;

    vec3 p = worldVector * res;
    vec3 id = floor(p);
    vec3 fp = fract(p) - 0.5;

    float rp = hash33(id).x;
    float stars = 1.0 - smoothstep(0.2, 0.5, length(fp));

    return stars * step(rp, 0.005);
}

#include "/lib/sky.glsl"

vec3 calcSky(in vec2 coord, out vec3 sky) {
    float fac;
    vec3 world = normalize(getWorldSpacePositionSky(coord).xyz);

    if (sunAngle > 0.5 && sunAngle <= 0.75) {
        fac = smoothstep(0.5, 0.55, sunAngle);
    } else if (sunAngle > 0.75) {
        fac = 1.0 - smoothstep(0.95, 1.0, sunAngle);
    } else {
        fac = 0.0;
    }

    vec3 skyCol = getSky(coord, fac, world, upPosition, lightVector);
    vec3 sunCol = getSun(coord, fac, sunPosition);
    vec3 moonCol = getMoon(coord, fac, sunPosition);
    vec3 starCol = vec3(1.0, 1.0, 0.95) * generateStars(world) * fac * (1.0 - rainStrength);    

    sky = texture2D(colortex6, coord).rgb;

    return skyCol + sunCol + moonCol + starCol;
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

vec3 getShadowSpacePosition(in vec2 coord, inout float fac) {
    vec4 positionWorldSpace = getWorldSpacePositionShadow(coord);

    positionWorldSpace.xyz -= cameraPosition;
    vec4 positionShadowSpace = shadowModelView * positionWorldSpace;
    positionShadowSpace = shadowProjection * positionShadowSpace;
    positionShadowSpace /= positionShadowSpace.w;

    float dist = sqrt(positionShadowSpace.x * positionShadowSpace.x + positionShadowSpace.y * positionShadowSpace.y);
    float distortFactor = (1.0f - 0.85) + dist * 0.85;

    positionShadowSpace.xy *= 1.0f / distortFactor;
    fac = 1.0f / distortFactor;

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

float getPenumbraWidth(in vec3 shadowCoord, in float factor, in sampler2D shadowTexture) {
    float dFragment = shadowCoord.z; //distance from pixel to light
    float dBlocker = 0.0; //distance from blocker to light
    float penumbra = 0.0;
    
    float shadowMapSample;
    float numBlockers = 0.0;

    float searchSize = LIGHT_SIZE / dFragment;

    for (int x = -PCSS_SAMPLE_COUNT; x < PCSS_SAMPLE_COUNT; x++) {
        for (int y = -PCSS_SAMPLE_COUNT; y < PCSS_SAMPLE_COUNT; y++) {
            vec2 sampleCoord = shadowCoord.st + (vec2(x, y) * searchSize / (shadowMapResolution * 25 * PCSS_SAMPLE_COUNT));
            shadowMapSample = texture2D(shadowTexture, sampleCoord, 2.0).r;

            dBlocker += shadowMapSample;
            numBlockers += 1.0;
        }
    }

    if(numBlockers > 0.0) {
		dBlocker /= numBlockers;
		penumbra = (dFragment - dBlocker) * LIGHT_SIZE / dFragment;
	}

    return clamp(max(penumbra, MIN_PENUMBRA_SIZE), 0.0, searchSize / 50);
}

vec3 getShadowColor(in vec2 coord) {
    float factor;

    vec3 shadowCoord = getShadowSpacePosition(coord, factor);
    vec3 shadowColor = vec3(0.0);

    #ifdef PCSS
        float penumbraSize1 = getPenumbraWidth(shadowCoord, factor, shadowtex1);
        float penumbraSize2 = getPenumbraWidth(shadowCoord, factor, watershadow);
    #else
        float penumbraSize1 = 1.0;
        float penumbraSize2 = 1.0;
    #endif
    
    int numSamples = 64;

    float shadowMapBias1;
    float shadowMapBias2;

    mat2 rotationMatrix = getRotationMatrix(coord);

    if (!(shadowCoord.x > 0.0 && shadowCoord.x < 1.0 && shadowCoord.y > 0.0 && shadowCoord.y < 1.0)) {
        return vec3(0.111);
    }

    for (int i = 0; i < numSamples; i++) {
        vec2 offset1 = disc64[i] / shadowMapResolution;
        vec2 offset2 = offset1;
        offset1 *= penumbraSize1;
        offset2 *= penumbraSize2;
        #ifdef RANDOM_ROTATION
            offset1 = rotationMatrix * offset1;
            offset2 = rotationMatrix * offset2;
        #endif

        shadowMapBias1 = 0.0005 * (length(offset1) + 0.75);
        shadowMapBias2 = 0.0005 * (length(offset2) + 0.75);

        vec2 adjustedShadowCoord1 = shadowCoord.st + offset1;
        vec2 adjustedShadowCoord2 = shadowCoord.st + offset2;
        
        vec2 zStep = shadowCoord.z - vec2(0.85, 0.85 * 2.0);

        float shadowMapSample = texture2D(shadowtex1, adjustedShadowCoord1).r;
        float visibility = step(shadowCoord.z - shadowMapSample, shadowMapBias1);
        
        float shadowMapSampleTransparent = texture2D(watershadow, adjustedShadowCoord2).r;
        float transparentVisibility = step(shadowCoord.z - shadowMapSampleTransparent, shadowMapBias2);

        float shadow0 = step(zStep.x, shadowMapSample);
        float shadow1 = step(zStep.x, shadowMapSampleTransparent);

        vec3 colorSample = texture2D(shadowcolor0, adjustedShadowCoord2).rgb;

        colorSample = mix(colorSample, vec3(1.0), transparentVisibility);
        colorSample = mix(vec3(0.0), colorSample, visibility);

        shadowColor += colorSample;
    }

    shadowColor /= numSamples;

    return shadowColor * 0.111;
}

struct Fragment {
    vec3 albedo;
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

float ctorspec(vec3 ppos, vec3 lvector, vec3 normal) {
    //half vector
	vec3 pos = -normalize(ppos);
    vec3 cHalf = normalize(lvector + pos);
	
    // beckman's distribution function D
    float normalDotHalf = dot(normal, cHalf);
    float normalDotHalf2 = normalDotHalf * normalDotHalf;

    float roughness2 = 0.05;
    float exponent = -(1.0 - normalDotHalf2) / (normalDotHalf2 * roughness2);
    float e = 2.71828182846;
    float D = pow(e, exponent) / (roughness2 * normalDotHalf2 * normalDotHalf2);
	//D *= texture2D(gaux1, texcoord.st).a;
	
    // fresnel term F
	float normalDotEye = dot(normal, pos);
    float F = pow(1.0 - normalDotEye, 5.0);

    // self shadowing term G
    float normalDotLight = dot(normal, lvector);
    float X = 2.0 * normalDotHalf / dot(pos, cHalf);
    float G = min(1.0, min(X * normalDotLight, X * normalDotEye));
    float pi = 3.1415927;
    float CookTorrance = (D*F*G)/(pi*normalDotEye);
	
    return max(CookTorrance/pi,0.0);
}

float getNoHSquared(float radiusTan, float NoL, float NoV, float VoL) { // From https://www.guerrilla-games.com/read/decima-engine-advances-in-lighting-and-aa
    float radiusCos = inversesqrt(1.0 + radiusTan * radiusTan);

    float RoL = 2.0 * NoL * NoV - VoL;
    if (RoL >= radiusCos)
        return 1.0;

    float rOverLengthT = radiusCos * radiusTan * inversesqrt(1.0 - RoL * RoL);
    float NoTr = rOverLengthT * (NoV - RoL * NoL);
    float VoTr = rOverLengthT * (2.0 * NoV * NoV - 1.0 - RoL * VoL);

    float triple = sqrt(clamp(1.0 - NoL * NoL - NoV - VoL * VoL + 2.0 * NoL * NoV * VoL, 0.0, 1.0));

    float NoBr = rOverLengthT * triple, VoBr = rOverLengthT * (2.0 * triple * NoV);
    float NoLVTr = NoL * radiusCos + NoV + NoTr, VoLVTr = VoL * radiusCos + 1.0 + VoTr;
    float p = NoBr * VoLVTr, q = NoLVTr * VoLVTr, s = VoBr * NoLVTr;
    float xNum = q * (-0.5 * p + 0.25 * VoBr * NoLVTr);
    float xDenom = p * q + s * ((s - 2.0 * p)) + NoLVTr * ((NoL * radiusCos + NoV) * VoLVTr * VoLVTr +
                   q * (-0.5 * (VoLVTr + VoL * radiusCos) - 0.5));
    float twoX1 = 2.0 * xNum / (xDenom * xDenom + xNum * xNum);
    float sinTheta = twoX1 * xDenom;
    float cosTheta = 1.0 - twoX1 * xNum;
    NoTr = cosTheta * NoTr + sinTheta * NoBr;
    VoTr = cosTheta * VoTr + sinTheta * VoBr;

    float newNoL = NoL * radiusCos + NoTr;
    float newVoL = VoL * radiusCos + VoTr;
    float NoH = NoV + newNoL;
    float HoH = 2.0 * newVoL + 2.0;
    return max(0.0, NoH * NoH / HoH);
}

float GGX (vec3 n, vec3 v, vec3 l, float r, float F0) {
  r*=r;r*=r;
  
  vec3 h = l + v;
  float hn = inversesqrt(dot(h, h));

  float dotLH = clamp(dot(h,l)*hn,0.,1.);
  float dotNL = clamp(dot(n,l),0.,1.);
  float dotNH = getNoHSquared(tan(radians(5.5)), dotNL, dot(n,v), dot(v,l));
  
  float denom = (dotNH * r - dotNH) * dotNH + 1.;
  float D = r / (3.141592653589793 * denom * denom);
  float F = F0 + (1. - F0) * exp2((-5.55473*dotLH-6.98316)*dotLH);
  float k2 = .25 * r;

  return dotNL * D * F / (dotLH*dotLH*(1.0-k2)+k2);
}

float OrenNayar(vec3 v, vec3 l, vec3 n, float r) {
    r *= r;
    
    float NdotL = dot(n,l);
    float NdotV = dot(n,v);
    
    float t = max(NdotL,NdotV);
    float g = max(.0, dot(v - n * NdotV, l - n * NdotL));
    float c = g/t - g*t;
    
    float a = .285 / (r+.57) + .5;
    float b = .45 * r / (r+.09);

    return max(0., NdotL) * ( b * c + a);
}

vec3 calculateLighting(in Fragment frag, in Lightmap lm, in vec2 coord) {
    float notNdotL = OrenNayar(-normalize(getCameraSpacePositionShadow(texcoord.st).xyz), lightVector, frag.normal, 0.5);
    float UdotL = dot(normalize(upPosition), lightVector);

    vec4 fragposition = gbufferProjectionInverse * vec4(texcoord.s * 2.0f - 1.0f, texcoord.t * 2.0f - 1.0f, 2.0f * getDepth(texcoord.st).r - 1.0f, 1.0f);
	fragposition /= fragposition.w;
    
    float specularIntensity = GGX(frag.normal, -normalize(fragposition.xyz), lightVector, clamp(texture2D(colortex5, texcoord.st).g, 0.1, 1.0), 0.0) * texture2D(colortex5, texcoord.st).r;
    //specularIntensity = ctorspec(fragposition.xyz, lightVector, normalize(frag.normal)) * texture2D(colortex3, texcoord.st).r;
    vec3 specularColor = clamp(specularIntensity, 0.0, 1.0) * lightColor;

    float directLightStrength = max(0.0, mix(notNdotL, UdotL, frag.emission));
    vec3 directLight = directLightStrength * lightColor;

    vec3 skyLight = skyColor * lm.skyLightStrength;

    vec3 torchColor = vec3(0.85, 0.5, 0.15) * 5.0;
    vec3 torchLight = torchColor * lm.torchLightStrength;

    vec3 nonDirectLight = max(skyLight, 0.025) + torchLight;

    vec3 shadowColor = getShadowColor(coord);

    vec3 litColor = frag.albedo * (directLight * shadowColor * lm.skyLightStrength + nonDirectLight) + specularColor * shadowColor;

    return litColor;
}

void desat(inout vec3 color, in float strength) {
	float amount = 0.8f;
	vec3 cyan = vec3(0.12f, 0.45f, 1.0f);
	float gray = dot(color, vec3(1.0f));

	color = mix(color, vec3(gray) * cyan, strength * amount);
    color *= 0.5;
}

float linearDepth(float depth) {
    if (isEyeInWater == 0) {
        return (2.0 * near - FOG_DENSITY + rainStrength * 0.15) / (FAR + near - FOG_DENSITY + rainStrength * 0.15 - depth * (FAR - near - FOG_DENSITY + rainStrength * 0.15));
    } else if (isEyeInWater == 1) {
        return (2.0 * near) / (FAR + near - depth * (FAR - near));
    } else if(isEyeInWater == 2) {
        return (2.0 * near) / (FAR + near - depth * (FAR - near));
    }
}

void fog(inout vec3 color, in vec3 sky, in Lightmap lm) {
    if (isEyeInWater == 0 || texture2D(depthtex1, texcoord.st).r > texture2D(depthtex0, texcoord.st).r) {
        color = mix(color, sky, clamp(pow(linearDepth(getDepth(texcoord.st).r) * 1.5, 1.5) * 0.8, 0.0, 0.75));
    } else if (isEyeInWater == 1) {
        color = mix(color, vec3(0.025) * WATER_COLOR, clamp(pow(linearDepth(getDepth(texcoord.st).r), 1.5) * 1.5, 0.0, 0.95) * (1.0 - nightVision));        
    } else if(isEyeInWater == 2) {
        color = mix(color, vec3(1.0, 0.15, 0.0), clamp(pow(linearDepth(getDepth(texcoord.st).r), 1.5) * 1.5 + 0.5, 0.0, 1.0));
    }
}

/* DRAWBUFFERS:0345 */

void main() {
    //vec4 worldPos = normalize(getWorldSpacePositionSky(texcoord.st));

    Fragment frag = getFragment(texcoord.st);
    Lightmap lm = getLightmapSample(texcoord.st);

    vec3 finalColor;
    vec3 sky;

    vec3 temp = calcSky(texcoord.st, sky);

    if (texture2D(depthtex0, texcoord.st) == vec4(1.0)) {
        finalColor = temp;
        
        //finalColor = calculateLighting(frag, lm, texcoord.st, true);
        //finalColor = vec3(fract(worldPos.xz), 0.0);
        //finalColor = texture2D(noisetex, worldPos.xz / worldPos.y).rgb;
    } else {
        finalColor = calculateLighting(frag, lm, texcoord.st);

        if (bool(isNight)) {
            desat(finalColor.rgb, pow((1.0 - lm.torchLightStrength), 256.0));
        }

        #ifdef FOG
            fog(finalColor, sky, lm);
        #endif
    }

    //FragData0 = vec4(vec3(fract(worldPos.xz / worldPos.y), 0.0), 1.0);
    //FragData0 = vec4(texture2D(gdepthtex, texcoord.st).rgb, 1.0);
    //FragData0 = vec4(vec3((getCameraDepthBuffer(texcoord.st)) / 50.0), 1.0);
    FragData0 = vec4(finalColor, 1.0);
    FragData1 = vec4(0.0);
    FragData2 = vec4(0.0);
    FragData3 = vec4(0.0, 1.0, 0.0, 1.0);
}
