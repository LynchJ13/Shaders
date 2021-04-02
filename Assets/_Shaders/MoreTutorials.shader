Shader "Tutorials/MoreTutorials"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Scale ("Size Scaling", Range(0.0,.5)) = .2
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Raymarching_Functions.cginc"

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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Scale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.ro = _WorldSpaceCameraPos;
                o.hitPos = mul(unity_ObjectToWorld, v.vertex);
                // o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
                // o.hitPos = v.vertex;
                return o;
            }

            float2 moda(float2 p, float per){
                float a = atan2(p.y,p.x);
                float l = length(p);
                a = fmod(a-per/2.,per)-per/2.;
                return float2(cos(a),sin(a))*l;
            }
            

            float tunnel(float3 p){
                float plane;// = dot(p-float3(0,1,0), normalize(float3(0,1,0)))+2;
                // plane = 0;

                float3 bp = p-float3(0,0,0)*_Scale;
                // bp.z += sin(bp.x*5.+_Time[1])*.06; // waving flag

                // mirroring axes
                bp = abs(bp);
                // bp.xz = moda(bp.xz, 2*PI/5);
                bp -= 1.;

                // bp.x -= 2;
                // float3 n = normalize(float3(0,0,0));
                // bp -= 2*n*min(0., dot(p,n));

                //TODO: find a way to elongate the y-axis
                float scale = lerp(1.,3., smoothstep(-1.,2.,bp.y));
                bp.xz *= scale;
                bp.xz = mul(Rot(smoothstep(-.5,1.,bp.y)), bp.xz);


                float b = box(bp, float3(1,1,1))/scale;
                // b -= sin(p.x*5+_Time[1]*3.)*.06*_Scale; // displacement mapping (looks like pumping)
                // both displacement and flag together looks cool
                // b = abs(b)-.1*.2; // shell

                float d = min(plane, b);
                d = b;
                // d = max(plane, b);
                return d;
            }
            float MapMarch(float3 p){
                float3 q = p-float3(0,0,0);
                q.xz = mul(Rot(smoothstep(0.5,2.,abs(p.y))), p.xz);
                return tunnel(q);
            }

            float Raymarch(float3 ro, float3 rd) {
                float dO = 0; // total distance from the origin we've marched
                float dS; // distance from the scene/surface
                for (int i = 0; i < MAX_STEPS; i++){
                    float3 p = ro + rd*dO;
                    dS = MapMarch(p);
                    dO += dS;
                    if ( abs(dS) < SURF_DIST || dO > MAX_DIST) break; // either we've hit the surface of the object, or we've gone past it
                }
                return dO;
            }

            // color a pixel based off it's normal
            float3 GetNormal(float3 p){
                float2 e = float2 (1e-2,0);
                float3 n = MapMarch(p) - float3 (
                    MapMarch(p-e.xyy),
                    MapMarch(p-e.yxy),
                    MapMarch(p-e.yyx)
                );
                return normalize(n);
            }

            float GetLight(float3 p) {
                float3 lightPos = float3(3, 5, 4)*.2;
                float3 l = normalize(lightPos-p);
                float3 n = GetNormal(p);
                
                float dif = clamp(dot(n, l)*.5+.5, 0., 1.);
                float d = Raymarch(p+n*SURF_DIST*2., l);
                if(p.y<.01 && d<length(lightPos-p)) dif *= .5;
                
                return dif;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv-.5;
                float dt = _Time[1];
                float3 ro = i.ro;
                float3 rd = normalize(i.hitPos - ro);

                float d = Raymarch(ro, rd);
                fixed4 col = 0;
                if (d >= MAX_DIST){
                    // discard;
                } else {
                    float3 p = ro + rd*d;
                    float3 n = GetLight(p);
                    col.rgb = n;
                }
                col = pow(col, .4545); // gamma correction
                return col;
            }
            ENDCG
        }
    }
}
