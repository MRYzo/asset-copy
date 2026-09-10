#version 330 core
#extension GL_ARB_explicit_attrib_location: enable

uniform sampler2D terrainTex;

in vec4 rgba;
in vec4 rgbaFog;
in float fogAmount;
in vec2 uv;
in float glowLevel;
in vec4 worldPos;
in vec3 blockLight;
in vec3 vertexPos;

in float normalShadeIntensity;
flat in int renderFlags;
flat in vec3 normal;

#include vertexflagbits.ash
#include fogandlight.fsh
#include noise3d.ash
#include colormap.fsh
#include underwatereffects.fsh
#include oit.fsh

void main() 
{
	// When looking through tinted glass you can clearly see the edges where we fade to sky color
	// Using this discard seems to completely fix that
	if (rgba.a < 0.005) discard;

	vec4 texColor = rgba * getColorMapped(terrainTex, texture(terrainTex, uv));

	if (psychedelicStrength > Epsilon) texColor = applyPsychedelicEffect(texColor, vertexPos.xyz, 0);

	float murkiness=getUnderwaterMurkiness();
	if (murkiness > 0) {
		texColor = applyFogAndShadowWithNormal(texColor, 0, normal, normalShadeIntensity, 0.45, worldPos.xyz);
		texColor.rgb = applyUnderwaterEffects(texColor.rgb, murkiness);	
	} else {	
		texColor = applyFogAndShadowWithNormal(texColor, fogAmount, normal, normalShadeIntensity, 0.45, worldPos.xyz);
	}	
	

#if SHINYEFFECT > 0
	float glow=0;
	texColor = mix(applyReflectiveEffect(texColor, glow, renderFlags, uv, normal, worldPos, worldPos, blockLight), texColor, min(1, 2 * fogAmount));
#endif	

    OIT(texColor, glowLevel);

}
