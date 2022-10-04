/**
 * Lift Gamma Gain version 1.1
 * by 3an and CeeJay.dk
 */

#include "ReShadeUI.fxh"

uniform float3 RGB_Lift < __UNIFORM_SLIDER_FLOAT3
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "RGB 阴影";
	ui_tooltip = "调整红色，绿色和蓝色的阴影。";
> = float3(1.0, 1.0, 1.0);
uniform float3 RGB_Gamma < __UNIFORM_SLIDER_FLOAT3
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "RGB 间调";
	ui_tooltip = "调整红、绿、蓝的中间调。";
> = float3(1.0, 1.0, 1.0);
uniform float3 RGB_Gain < __UNIFORM_SLIDER_FLOAT3
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "RGB 高光";
	ui_tooltip = "调整红色、绿色和蓝色的高光。";
> = float3(1.0, 1.0, 1.0);


#include "ReShade.fxh"

float3 LiftGammaGainPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	
	// -- Lift --
	color = color * (1.5 - 0.5 * RGB_Lift) + 0.5 * RGB_Lift - 0.5;
	color = saturate(color); // Is not strictly necessary, but does not cost performance
	
	// -- Gain --
	color *= RGB_Gain; 
	
	// -- Gamma --
	color = pow(abs(color), 1.0 / RGB_Gamma);
	
	return saturate(color);
}


technique LiftGammaGain
<
	ui_label = "提升伽马获得";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LiftGammaGainPass;
	}
}
