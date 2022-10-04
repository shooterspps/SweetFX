/**
 * Color Matrix version 1.0
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * ColorMatrix allow the user to transform the colors using a color matrix
 */

#include "ReShadeUI.fxh"

uniform float3 ColorMatrix_Red < __UNIFORM_SLIDER_FLOAT3
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "矩阵红";
	ui_tooltip = "新红色值应该包含多少红色、绿色和蓝色调。如果你不希望改变亮度，总和应该是1.0。";
> = float3(0.817, 0.183, 0.000);
uniform float3 ColorMatrix_Green < __UNIFORM_SLIDER_FLOAT3
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "矩阵绿";
	ui_tooltip = "新绿色值应该包含多少红色、绿色和蓝色调。如果你不希望改变亮度，总和应该是1.0。";
> = float3(0.333, 0.667, 0.000);
uniform float3 ColorMatrix_Blue < __UNIFORM_SLIDER_FLOAT3
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "矩阵蓝";
	ui_tooltip = "新蓝色值应该包含多少红色、绿色和蓝色调。如果你不希望改变亮度，总和应该是1.0。";
> = float3(0.000, 0.125, 0.875);

uniform float Strength < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "强度";
	ui_tooltip = "调整效果的强度。";
> = 1.0;

#include "ReShade.fxh"

float3 ColorMatrixPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	const float3x3 ColorMatrix = float3x3(ColorMatrix_Red, ColorMatrix_Green, ColorMatrix_Blue);
	color = lerp(color, mul(ColorMatrix, color), Strength);

	return saturate(color);
}

technique ColorMatrix
<
	ui_label = "颜色矩阵";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ColorMatrixPass;
	}
}
