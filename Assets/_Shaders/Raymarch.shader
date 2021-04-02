Shader "Tutorials/Raymarch"
{
    Properties
    {
        // PROPERTIES WINDOW
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
            #define MAX_STEPS 100
            #define MAX_DIST 100.
            #define SURF_DIST 1e-2

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ro : TEXCOORD1;
                float3 hitPos : TEXCOORD2;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
                // o.ro = _WorldSpaceCameraPos; // in World-Space coordsz
                o.hitPos = v.vertex;    // In object-space coords
                // o.hitPos = mul(unity_ObjectToWorld,v.vertex);  // convert the hitPos to worldspace coords
                return o;
            }

            float GetDist(float3 p){
                float d = length(p) - 0.5; // sphere
                d = length(float2(length(p.xz)-.5, p.y)) -.1;

                return d;
            }

            float Raymarch(float3 ro, float3 rd) {
                float dO = 0; // total distance from the origin we've marched
                float dS; // distance from the scene/surface
                for (int i = 0; i < MAX_STEPS; i++){
                    float3 p = ro + rd*dO;
                    dS = GetDist(p);
                    dO += dS;
                    if ( dS < SURF_DIST || dO > MAX_DIST) break; // either we've hit the surface of the object, or we've gone past it
                }
                return dO;
            }

            float3 GetNormal(float3 p){
                float2 e = float2 (1e-2,0);
                float3 n = GetDist(p) - float3 (
                    GetDist(p-e.xyy),
                    GetDist(p-e.yxy),
                    GetDist(p-e.yyx)
                );
                return normalize(n);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv-.5;
                float3 ro = i.ro; //origin of the ray
                float3 rd = normalize(i.hitPos - ro);// normalize(float3(uv.x, uv.y, 1)); // direction of the ray

                float d = Raymarch(ro, rd);
                fixed4 col = 0;
                if (d >= MAX_DIST){
                    discard;
                } else {
                    float3 p = ro + rd*d;
                    float3 n = GetNormal(p);
                    col.rgb = n;
                }
                // col.rgb = rd;
                return col;
            }
            ENDCG
        }
    }
}
