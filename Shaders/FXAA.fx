/**
 *                                  FXAA 3.11
 *
 *                               for ReShade 3.0+
 */

#include "ReShadeUI.fxh"

uniform float Subpix < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "子像素";
	ui_tooltip = "子像素混叠去除的分流。较高的值使图像更柔和/模糊。";
> = 0.25;

uniform float EdgeThreshold < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "边缘检测阈值";
	ui_tooltip = "应用算法所需的最小局部对比度。";
> = 0.125;
uniform float EdgeThresholdMin < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "黑阈值";
	ui_tooltip = "为了提高性能，比这个颜色深的像素不会被处理。";
> = 0.0;

//------------------------------ Non-GUI-settings -------------------------------------------------

#ifndef FXAA_QUALITY__PRESET
	// Valid Quality Presets
	// 10 to 15 - default medium dither (10=fastest, 15=highest quality)
	// 20 to 29 - less dither, more expensive (20=fastest, 29=highest quality)
	// 39       - no dither, very expensive
	#define FXAA_QUALITY__PRESET 15
#endif

#ifndef FXAA_LINEAR_LIGHT
	#define FXAA_LINEAR_LIGHT 0
#endif

#ifndef FXAA_GREEN_AS_LUMA
	#define FXAA_GREEN_AS_LUMA 0
#endif

//-------------------------------------------------------------------------------------------------

#if (__RENDERER__ == 0xb000 || __RENDERER__ == 0xb100 || __RENDERER__ >= 0x10000)
	#define FXAA_GATHER4_ALPHA 1
	#if (__RESHADE__ < 40800)
		#define FxaaTexAlpha4(t, p) tex2Dgather(t, p, 3)
		#define FxaaTexOffAlpha4(t, p, o) tex2Dgatheroffset(t, p, o, 3)
		#define FxaaTexGreen4(t, p) tex2Dgather(t, p, 1)
		#define FxaaTexOffGreen4(t, p, o) tex2Dgatheroffset(t, p, o, 1)
	#else
		#define FxaaTexAlpha4(t, p) tex2DgatherA(t, p)
		#define FxaaTexOffAlpha4(t, p, o) tex2DgatherA(t, p, o)
		#define FxaaTexGreen4(t, p) tex2DgatherG(t, p)
		#define FxaaTexOffGreen4(t, p, o) tex2DgatherG(t, p, o)
	#endif
#endif

#define FXAA_PC 1
#define FXAA_HLSL_3 1

// Green as luma requires non-linear colorspace
#if FXAA_GREEN_AS_LUMA || BUFFER_COLOR_BIT_DEPTH == 10
	#undef FXAA_LINEAR_LIGHT
#endif

#include "FXAA.fxh"
#include "ReShade.fxh"

// Samplers

sampler FXAATexture
{
	Texture = ReShade::BackBufferTex;
	MinFilter = Linear; MagFilter = Linear;
#if FXAA_LINEAR_LIGHT
	SRGBTexture = true;
#endif
};

// Pixel shaders

#if !FXAA_GREEN_AS_LUMA
float4 FXAALumaPass(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 color = tex2D(ReShade::BackBuffer, texcoord.xy);
	color.a = sqrt(dot(color.rgb * color.rgb, float3(0.299, 0.587, 0.114)));
	return color;
}
#endif

float4 FXAAPixelShader(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return FxaaPixelShader(
		texcoord, // pos
		0, // fxaaConsolePosPos
		FXAATexture, // tex
		FXAATexture, // fxaaConsole360TexExpBiasNegOne
		FXAATexture, // fxaaConsole360TexExpBiasNegTwo
		BUFFER_PIXEL_SIZE, // fxaaQualityRcpFrame
		0, // fxaaConsoleRcpFrameOpt
		0, // fxaaConsoleRcpFrameOpt2
		0, // fxaaConsole360RcpFrameOpt2
		Subpix, // fxaaQualitySubpix
		EdgeThreshold, // fxaaQualityEdgeThreshold
		EdgeThresholdMin, // fxaaQualityEdgeThresholdMin
		0, // fxaaConsoleEdgeSharpness
		0, // fxaaConsoleEdgeThreshold
		0, // fxaaConsoleEdgeThresholdMin
		0 // fxaaConsole360ConstDir
	);
}

// Rendering passes

technique FXAA
<
	ui_label = "锐化-FXAA";
>
{
#if !FXAA_GREEN_AS_LUMA
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = FXAALumaPass;
	}
#endif
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = FXAAPixelShader;
#if FXAA_LINEAR_LIGHT
		SRGBWriteEnable = true;
#endif
	}
}
