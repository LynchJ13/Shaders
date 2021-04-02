Shader "Superbia/Tunnel"
{
    Properties
    {
        // _MainTex ("Texture", 2D) = "white" {}
        _TunnelSizeX ("Tunnel Size (X)",Range(1.0,100.)) = 1.0
        _TunnelRotSpeed("Tunnel Rot Speed",Range(-5.0,5.0)) = 1.0
        _TunnelThickness ("Tunnel Thickness", Range(0.0,1.0)) = 0.8
        _TunnelSmall ("Tunnel End Size", Range(0.1, .5)) = 0.5
        _TunnelLarge ("Tunnel Middle Size", Range(1.0, 1.5)) = 1.0
        _TunnelRotScale ("Tunnel Sprial Amount", Range(0,1.)) = 0.5
        _TunnelShapes ("Tunnel Shape Iter", Range(0,1.)) = 0.0
        _SliceThickness ("Slice Thickness", Range(0.0,0.495)) = 0.0
        _SliceSpeed ("Slice Speed", Range(-5.0,5.0)) = 0.0
        _ShowSlices ("Show Slices", Range(0.0,1.0)) = 0.0
        _Mix ("Mix Amount", Range(0.0,1.0)) = 0.0
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

            // sampler2D _MainTex;
            // float4 _MainTex_ST;
            float _TunnelRotScale;
            float _TunnelSizeX;
            float _TunnelThickness;
            float _TunnelLarge;
            float _TunnelSmall;
            float _TunnelShapes;
            float _ShowSlices;
            float _SliceThickness;
            float _SliceSpeed;
            float _Mix;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                // o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
                // o.hitPos = v.vertex;
                o.ro = _WorldSpaceCameraPos; // in World-Space coords
                o.hitPos = mul(unity_ObjectToWorld,v.vertex);  // convert the hitPos to worldspace coords
                return o;
            }

            float2 Rot2D (float2 q, float a)
            {
            return q * cos (a) + q.yx * sin (a) * float2 (-1., 1.);
            }

            float hollow (float prim, float thicc){
                return abs(prim)-.2*.2;
            }

            float iterator(){
                
            }

            // creates the individual bars of the cage.
            float bar (float3 p){
                float3 bp = p;
                // float scale = 1.0 - smoothstep(-.5,-.25,bp.y)*smoothstep(.5,.25,bp.y);
                // scale = lerp(_Slide,_Slide2,scale);
                // bp.xz *= scale;
                float b = box( bp, float3(_TunnelSizeX-1,1,1) );
                // b /= scale;
                return b;
            }

            // creates the frame for the cage
            float cage (float3 p){
                // create the lantern frame
                float3 cp = p-float3(0,0,0);    // set the position of the cage position
                float pumpAmt = smoothstep(-_TunnelSizeX,0.5,cp.x)*smoothstep(_TunnelSizeX,0.1,cp.x);
                float scale = .1*lerp(_TunnelSmall,_TunnelLarge, pumpAmt);
                cp.zy = mul(Rot(smoothstep(-_TunnelSizeX,_TunnelSizeX,cp.x)*_TunnelRotScale*PI), cp.zy);                                // rotates the bars about y-axis
                cp.zy = abs(cp.zy);                                                                 // mirrors bars on xz-plane
                // cp.zy = mul ( Rot(_RotScale), cp.zy);
                cp.zy -= /* .2*abs(sin(cp.x+(PI/2)))* */smoothstep(-_TunnelSizeX,0.5,cp.x)*smoothstep(_TunnelSizeX,0.1,cp.x);   // moves the x back to make that bell curve of the cage

                // cp.zy = mul(Rot(smoothstep(-.4,.4,cp.x)*2*PI+_Time[1]), cp.zy);                     // spindels bars
                cp.zy /= scale;
                float b = bar(cp);
                b *= scale;
                b *= sqrt(2);
                return b;
            }

            float tunnel(float3 p){
                float3 tp = p;

                // tp.zy /= smoothstep(-1.0,0.0,tp.x)*smoothstep(1.0,0.0,tp.x);
                float pumpAmt = smoothstep(-_TunnelSizeX,0.,tp.x)*smoothstep(_TunnelSizeX,0.0,tp.x);
                // pumpAmt = max(smoothstep(-1.,0.,tp.x)*smoothstep(1.,0.,tp.x), step(tp.x,-1.0)+step(1.0,tp.x)); 
                float scale = lerp( _TunnelSmall , _TunnelLarge, pumpAmt );
                // scale = 1.;
                tp.zy /= scale;

                // tp.zy = mul( Rot(sin(floor(tp.x)*_RotScale + _Time[1])), tp.zy);
                // tp.zy = mul ( Rot(floor(tp.x)*_RotScale), tp.zy);
                float _m = lerp(tp.x,floor(tp.x),_Mix);
                tp.zy = mul ( Rot(_m*_TunnelRotScale), tp.zy);
                float t = box(tp, float3(_TunnelSizeX,1,1) );
                float o = sdOctahedron(tp, 1.);
                t = lerp(t,o,_TunnelShapes);
                t = hollow(t, 2.0);

                // hollow (TODO: make function)
                // float3 hp = tp;
                // float h = box(hp, float3(_TunnelSizeX+.01,_TunnelThickness,_TunnelThickness) );
                // t = opSubtraction(h,t);

                // create the slice box
                // size of the "tile" (c), and how many repititions (l)
                float c = 1;
                float3 l = float3(round(_TunnelSizeX),0,0);
                float3 rs = tp+float3(fmod(_Time[1]*_SliceSpeed,1.0),0,0);
                rs = rs-c*clamp(round(rs/c),-l,l);
                float s = box(rs, float3(_SliceThickness,1.1,1.1));
                // s = box(rs, float3(.1,2,2));
                // s *= scale;
                float b = cage (p);
                // return b;

                float st = opSubtraction(s,t);
                t = lerp(t,st,_ShowSlices);
                // return s;

                // replicate the slice box along the x-axis
                
                t *= scale;
                // t = min (t,b);
                return t;
            }
            
            float3 opRepLim( in float3 p, in float c, in float3 l/* , in sdf3d primitive */ )
            {
                float3 q = p-c*clamp(round(p/c),-l,l);
                return tunnel( q );
            }

            float MapMarch(float3 p){
                // have each sector rotate by a factor of 15deg.
                // float3 rotP = p;
                // float sf = sin(floor(rotP.x+.5));
                // rotP.zy = mul( Rot(sin(floor(rotP.x+.5)*_RotScale + _Time[1])), rotP.zy); 
            
                // rotP.zy *= sf;

                return tunnel(p);
                // return opRepLim(rotP, 1, float3(10,0,0));
                // return tunnel(p);
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
                float3 lightPos = float3(0,0,0);
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
                float3 ro = i.ro;
                float3 rd = normalize(i.hitPos - ro);

                float d = Raymarch(ro, rd);
                fixed4 col = 0;
                if (d >= MAX_DIST){
                    d = MAX_DIST;
                    // discard;
                } else {
                    float3 p = ro + rd*d;
                    float3 n = GetLight(p);
                    // n= GetNormal(p);
                    col.rgb = n;
                    // col.rgb = 1;
                }
                // col *= exp2(-.15 * d);
                return col;
            }
            ENDCG
        }
    }
}
