Shader "Superbia/Helix_Raymarch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Twist ("Twist Amount", Range(0,20)) = 0.0
        _Scale ("Scale Amount", Range(0,1.0)) = 0.2

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
            #include "Raymarching_Functions.cginc"
            // #define MAX_STEPS 100
            // #define MAX_DIST 100.
            // #define SURF_DIST 1e-3

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
            float _Twist;
            float _Scale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
                o.hitPos = v.vertex;
                return o;
            }
            
            float displacement(float3 p){
                float d = 2.f;
                return sin(d*p.x)*sin(d*p.y)*sin(d*p.z);
            }

            float displace( float3 p ){ 
                float d1 = cylinderInf(p, float3(0,0,.05));
                float d2 = displacement(p);
                return d1+d2;
            }

            // modularly divide angle (ie. allows for slices of "pie")
            float2 moda(float2 p, float per){
                float a = atan2(p.y,p.x);
                float l = length(p);
                a = fmod(a-per/2.,per)-per/2.;
                return float2(cos(a),sin(a))*l;
            }
            
            

            float multiHelix(float3 p){
                p.xz = mul(Rot(p.y*0.5+_Time[1]), p.xz);
                p.xz = moda(p.xz,2*PI/2)*1;
                p.x -= .4;
                /* float x=0;
                x = (4*cos(p.y+_Time[1]))*.05;
                float z = 0;
                z = (4*sin(p.y+_Time[1]))*.05; */
                // return cylinderInf(p, float3(,0,r))*.2;
                return cylinderCapped(p, .1, 1);
                // return min(cylinderInf(p, float3(x,z,r) )*.2,cylinderInf(p, float3(x0,z0,r) )*.2);
            }

            float tunnel(float3 p){
                // don't make helix here
                // p.yz = mul(Rot(PI/2.), p.yz);

                // float z0;
                // z0 = (sin(8*p.y+_Time[1]+phi))*_Scale;

                // z *= sin(p.y)*.2*helixRadius;
                return multiHelix(p);

                // expensive double helix, use moda() instead.
            }

            // Map all the shapes and shit for your shader here.
            float MapMarch(float3 p){
                float t = tunnel(p);
                // float s = circle(p, 10);
                // s = abs(s)-1;
                float g = dot(p-float3(0,1,0), normalize(float3(0,1,0)))+2;
                return min(t, g);
                // return s;
            }

            float Raymarch(float3 ro, float3 rd) {
                float dO = 0; // total distance from the origin we've marched
                float dS; // distance from the scene/surface
                for (int i = 0; i < MAX_STEPS; i++){
                    float3 p = ro + rd*dO;
                    dS = MapMarch(p);
                    dO += dS;
                    if (dO > MAX_DIST || abs(dS) < SURF_DIST) break; // either we've hit the surface of the object, or we've gone past it
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
                float dt = _Time[1]%(2*PI);
                float3 ro = i.ro;
                // ro += float3(0,dt,0);
                float3 rd = normalize(i.hitPos - ro);

                float d = Raymarch(ro, rd);
                fixed4 col = 0;
                if (d >= MAX_DIST){
                    discard;
                } else {
                    float3 p = ro + rd*d;
                    float3 n = GetLight(p);
                    col.rgb = n;
                    // col.rgb = 1;
                }
                return col;
            }
            ENDCG
        }
    }
}
