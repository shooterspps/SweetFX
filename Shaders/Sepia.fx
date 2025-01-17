#include "ReShadeUI.fxh"

uniform float3 Tint < __UNIFORM_COLOR_FLOAT3
	ui_label = "着色";
> = float3(0.55, 0.43, 0.42);

uniform float Strength < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "强度";
	ui_tooltip = "调整效果的强度。";
> = 0.58;

#include "ReShade.fxh"

float3 TintPass(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 col = tex2D(ReShade::BackBuffer, texcoord).rgb;

	return lerp(col, col * Tint * 2.55, Strength);
}

technique Tint
<
	ui_label = "着色";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = TintPass;
	}
}
