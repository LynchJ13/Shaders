Shader "Unlit/SolarFlare"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work

            #include "UnityCG.cginc"
            #include "gaborynoise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture

                float2 uv = i.uv;
                float2 R = _ScreenParams.xy/2500.0f,
                        S = 8. / R.yy,
                        U = ( 2.*uv - R ) * S, I = floor(U);
                    
                    A = 0.;   // anisotropy
                    D = 6.28* cos(uv.x+.3*_Time[1]) * cos(uv.y-.2*_Time[1]); // fiber direction
                phase  = _Time[1];  // phase, along the Gabor field direction 
                // phaseY = _Time[1];  // orthophase, along the front direction
                    
                    U = U/8.;
                float v = .5 + .5* cascade(U);
                    
                // v *= .01/fwidth(v);

                float4 O = v*float4(1,1,1,1); // coloring

                return O;



                // return col;
            }
            ENDCG
        }
    }
}
