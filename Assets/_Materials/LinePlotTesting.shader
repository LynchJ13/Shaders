Shader "Dev/LinePlotTesting"
{
    Properties
    {

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

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            float Hash(float n){return frac(sin(n) * 43758.5453123);}

            float gnoise( in float p )
            {
                float i = floor(p);
                float f = frac(p);
                float u = f*f*(3.0-2.0*f);
                return lerp( Hash(i)*(f-0.0), 
                            Hash(i+1.)*(f-1.0), u);
            }
            float fbm(float x, float H){
                float t = 0.0;
                for (int i = 0; i < 4; i++){
                    float f = pow(2.0, float(i) );
                    float a = pow(f, -H);
                    t += a * gnoise(f*x);
                }
                return t;
            }


            float plot(float2 st, float pct){
                return  smoothstep( pct-0.02, pct, st.y) -
                        smoothstep( pct, pct+0.02, st.y);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // get the uv
                float2 uv = i.uv;
                uv -= .5;
                float y = fbm(uv.x+_Time[1], 1);
                float3 c = float3(y,y,y);
                float pct = plot(uv,y);
                c = (1.0-pct)*c+pct*float3(0.0,1.0,0.0);
                
                return fixed4(c, 1.0);
            }
            ENDCG
        }
    }
}
