///////////////////////////////////////////////////////
// For use in MechWarrior Online
// Converts greyscale heat vision to color heat vision
// Credit : Alcom Isst https://github.com/Alcom1
///////////////////////////////////////////////////////

#include "ReShade.fxh"

#define TEXFORMAT RGBA8

//Default UIMask is unreliable, ColoredHeatVision has its own UIMask.
texture tUIMask_Mask_CHV <source="UIMask.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler sUIMask_Mask_CHV { Texture = tUIMask_Mask_CHV; };

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
    float r = value * 6 - 2;              //Red for lighttones
    float g = 1.5 - abs(value * 6 - 2.5); //Green for midtones
    float b = 1 - abs(value * 6 - 1);     //Blue for darktones
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
        float mask = Avg(tex2D(sUIMask_Mask_CHV, uv).rgb);

        //Final color is lerped between the before and after color based on the UI mask
        colorInput.rgb = lerp(colorInput.rgb, newColor.rgb, mask);
    }

	return colorInput;  //Return the modified or unmodified color
}


//Technique
technique ColoredHeatVision
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = GreyscaleToRainbow;
	}
}