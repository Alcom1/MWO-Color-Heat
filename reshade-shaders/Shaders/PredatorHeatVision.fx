///////////////////////////////////////////////////////
// For use in MechWarrior Online
// Converts greyscale heat vision to color/predator heat vision
// Credit : Alcom Isst https://github.com/Alcom1
///////////////////////////////////////////////////////

#include "ReShade.fxh"

//Setting - use mask
uniform bool settingUseMask <
    ui_label = "Use Mask";
    ui_tooltip = "Use the UI Mask to exclude UI elements from the filter.";
> = true;

//Setting - strength of the color spectrum
uniform float settingSpectrumStrength <
    ui_label = "Spectrum Strength";
	ui_type = "drag";
	ui_min = 0.0;
    ui_max = 20.0;
	ui_tooltip = "Strength of the spectrum. A higher value means more greens and reds.";
> = 5.0;

//Default UIMask is unreliable, PredatorHeatVision has its own UIMask.
texture textureMaskPredator <source="PredatorMask.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler samplerMaskPredator { Texture = textureMaskPredator; };

//Return the average value of a float3's components
float Avg(float3 value)
{
    return((value.x + value.y + value.z) / 3);
}

//Convert a greyscale value to a hue.
//Forumula has been heavily modified to fit MWO's greyscale spectrum
//Original formula at https://stackoverflow.com/a/19873710
float3 ValueToHue(float value)
{
    float r = value * settingSpectrumStrength - 2;                        //Red for lighttones
    float g = 1.5 - abs(value * settingSpectrumStrength - 2.5);           //Green for midtones
    float b = abs(abs(value * settingSpectrumStrength - 1) - 2) - 1;      //Blue for darktones and max heat
    return saturate(float3(r, g, b));     //Limit RGB to 0-1 and return as a float3 color
}

//Pixel shader to convert greyscale colors to 
float4 GreyscaleToRainbow(float4 vpos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
	float4 colorInput = tex2D(ReShade::BackBuffer, uv.xy);    //Color of the current pixel

    //Condition: If color is greyscale
    if(
        (colorInput.r == colorInput.g) && 
        (colorInput.r == colorInput.b))
    {
        //Convert the rgb color from a greyscale value to a hue
        float3 newColor = ValueToHue(Avg(colorInput));

        //Get the value fromt the UI mask
        float mask = settingUseMask ? Avg(tex2D(samplerMaskPredator, uv).rgb) : 1.0;

        //Final color is lerped between the before and after color based on the UI mask
        colorInput.rgb = lerp(colorInput.rgb, newColor.rgb, mask);
    }

	return colorInput;  //Return the modified or unmodified color
}


//Technique
technique PredatorHeatVision
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = GreyscaleToRainbow;
	}
}