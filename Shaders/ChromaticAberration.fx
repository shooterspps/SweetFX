/**
 * Chromatic Aberration
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Distorts the image by shifting each color component, which creates color artifacts similar to those in a very cheap lens or a cheap sensor.
 */

#include "ReShadeUI.fxh"

uniform float2 Shift < __UNIFORM_SLIDER_FLOAT2
	ui_min = -10; ui_max = 10;
	ui_label =  "变换";
	ui_tooltip = "以像素为单位的距离(X,Y)，以移动颜色组件。对于稍微模糊的外观，请尝试两个像素之间的小数值(.5)。";
> = float2(2.5, -0.5);
uniform float Strength < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "强度";
> = 0.5;

#include "ReShade.fxh"

float3 ChromaticAberrationPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color, colorInput = tex2D(ReShade::BackBuffer, texcoord).rgb;
	// Sample the color components
	color.r = tex2D(ReShade::BackBuffer, texcoord + (BUFFER_PIXEL_SIZE * Shift)).r;
	color.g = colorInput.g;
	color.b = tex2D(ReShade::BackBuffer, texcoord - (BUFFER_PIXEL_SIZE * Shift)).b;

	// Adjust the strength of the effect
	return lerp(colorInput, color, Strength);
}

technique CA
<
	ui_label = "色差";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ChromaticAberrationPass;
	}
}
