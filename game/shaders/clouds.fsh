#version 330 core
#extension GL_ARB_explicit_attrib_location: enable

in vec4 rgbaCloud;
in vec4 rgbaFog;
in vec3 plightrgb;
in float fogAmountf;
in float nightVisionStrengthv;

in vec3 vertexPos;
flat in int flagsf;
in float thinCloudModef;

uniform float fogDensityIn;
uniform float fogMinIn;
uniform vec3 sunPosition;


#include noise3d.ash
#include dither.fsh
#include fogandlight.fsh
#include skycolor.fsh
#include underwatereffects.fsh
#include oit.fsh

float halfsmooth(float x, float t){
    return x > t ? (x - t / 2.0) : (x * x * x * (1.0 - x * 0.5 / t) / t / t);
}

void main()
{
	float sealevelOffsetFactor = 0.25;
	float dayLight = 1;
	float horizonFog = 0;
	// Due to earth curvature the clouds are actually lower, so we do +100 to not have them dismissed during sunglow coloring
	vec4 skyGlow = getSkyGlowAt(vec3(vertexPos.x, vertexPos.y+100, vertexPos.z), sunPosition, sealevelOffsetFactor, clamp(dayLight, 0, 1), horizonFog, 0.7);
	
	vec4 col = rgbaCloud;
	
	col.a = (col.a)/(col.a +0.5)*1.5;
	
	col.rgb *= mix(vec3(1), 1.2 * skyGlow.rgb, skyGlow.a);
	col.rgb *= max(1, 0.9 + skyGlow.a/10);
	
	float baseBloom = max(0.0, 0.25 - fogAmountf/2);
	#if BLOOM == 1
		col.rgb *= 1 - baseBloom;
	#endif
	
	if (psychedelicStrength > Epsilon) col = applyPsychedelicEffect(col, vertexPos.xyz, 1);
	
	col.rgb = mix(col.rgb, rgbaFog.rgb, fogAmountf) + plightrgb;

	col.rgb += vec3(0.1, 0.5, 0.1) * nightVisionStrengthv;

	

	// Seems to give a ~8 FPS boost on an intel hd 620 when looking at the sky at 128 view distance
	if (col.a < 0.005) discard;
	
	float ldepth = texture(liquidDepth, gl_FragCoord.xy/frameSize.xy).r;
	if (ldepth < gl_FragCoord.z) {
		float murkiness = max(0.0, getSkyMurkiness() - 14*fogDensityIn);
		col.rgb = applyUnderwaterEffects(col.rgb, murkiness);
	}

    // fake depth for better blending
    float faux = halfsmooth((gl_FragCoord.z * 2.0 - 1.0) / gl_FragCoord.w, 500.0);

    OIT(col, 0.0, faux);

    outGlow = vec4(max(0, skyGlow.a/10 + baseBloom), 0, 0, min(1, col.a*5 - (flagsf >= 5 ? thinCloudModef : 0)));

}
