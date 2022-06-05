Shader "ChiChi/SH"
{
    Properties
    {
       _Smoothness("Smoothness",Range(0,1)) = 0
       _Cubemap ("CubeMap", CUBE) = ""{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags {  }
            Cull Off
           
            HLSLPROGRAM

            #pragma vertex SH_Lighting_Vertex
            #pragma fragment SH_Lighting_Fragment
            #include "Assets/Scenes/SH.hlsl"
            ENDHLSL
        }
    }
}
