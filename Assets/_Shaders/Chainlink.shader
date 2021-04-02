Shader "Superbia/Chainlink"
{
    Properties
    {
        // _MainTex ("Texture", 2D) = "white" {}
        _Slide ("Slider value", Range(-1,1)) = 1.0
        _Slide2 ("2nd Slider value", Range(-1,1)) = 1.0
        _Slide3 ("3rd Slider value", Range(-1,1)) = 1.0
        _Speed("Speed Value", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull off // allows me to look inside the shader

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
            float _Slide;
            float _Slide2;
            float _Slide3;
            float _Speed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
                o.hitPos = v.vertex;
                return o;
            }

            float2 moda(float2 p, float per){
                float a = atan2(p.y,p.x);
                float l = length(p);
                a = fmod(a-per/2.,per)-per/2.;
                return float2(cos(a),sin(a))*l;
            }
            
            float sliceBox (float3 p){
                float t = cos(_Time[1]);
                float3 sp = p-float3(0,t,0);
                return box( sp, float3(1,.05,1));
            }

            /* TODO: 
            Crescent Moon idea
            - Capped Torus where radius increments to look like a moon
            
            Lightning around crystal:
            - have cylinders travel up following the rotation of the bars
            - union the cylinders, bars, and crystal
            - use a sawtooth function for lightning
            - differentiate this from how it reduplicates the bars, you want them all to be traveling upward offset from each other.
            - create it in inner cage

            Morph when shaking:
            - when I shake the object have stuff morph
                - Wobble function (have that control amplitude of wobble)
                

            Orbs: two orbs moving around in a helix

            Orbit triangle: make a triangle orbit the crystal

            tendril effect on cage:
            - lower the size of the bars to 0, would probably attach to that lerp function for the scaling

            Boid idea
            - when you shake the object, the inside crystal breaks up into boids
            
            */

            float2 Rot2D (float2 q, float a)
            {
            return q * cos (a) + q.yx * sin (a) * float2 (-1., 1.);
            }

            float lightning(float3 p){
                float tCur = _Time[1];
                float f = 0.1;
                float3 q = p;
                // q.xy = abs(q.xy);
                q.xy = mul(Rot(PI/2), q.xy);
                q.yz = mul(Rot(tCur*PI), q.yz);
                // q.xz = mul(Rot(tCur), q.xz);
                q.x += frac(tCur)-.5;
                q.xz -= (1.0 - smoothstep(-.5,-.1,q.y)*smoothstep(.5,.1,q.y)) * float2(Fbm1(q.y+_Time[2]),Fbm1(q.y+_Time[2]+1.)); // convert this to 3D
                // q.y -= sin(tCur);
                float d;
                d = cylinderCapped (q, .01, 1);
                return d;

            }
            /*
            float orbit_ball(float3 p){
                float3 offset = float3(0,0,0);
                float3 op = p-offset;
                return circle(p, _Slide);
            } */

            float crystal(float3 p){
                // get Time values
                float t = _Time[1]*0.08;
                float st = _SinTime.a;
                float y = p.y;
                float3 offset = float3(0,0,0);
                float3 cp = p-offset;              // set the position of the crystal
                float scale = .6;

                st *= 0.08;
                // cp.y += st;                        // adjust Y-pos using _SinTime
                float w = sin(t*st)*st;            // wobble function
                cp.yz = mul(Rot(w), cp.yz);        // rotates the x-axis based on the wobble value (w)
                cp.xz /= scale;                    // makes this look more like a diamond
                cp.xz = mul(Rot(_Time[1]), cp.xz); // constant y-axis rotation
                // for use w/ circles
                // cp -= float3()
                // cp -= float3(cos(y), 0, sin(y)); // orbitin shell
                // cp -= float3(cos(y), y, sin(y)); // helix
                float r = abs(st*sin(t*4))*.4+.15;
                float c = sdOctahedron( cp , r );
                float e = circle(cp, r);
                c *= scale;
                e *= scale;
                float m = opMorph(c,e,_Speed);
                return m;
            }

            float innerCage(float3 p){
                float t;        // get the total value of the scene
                float c = crystal(p);   // creates the center crystal
                // float o = orbit_ball(p);       // creates a little orb that moves around the bigger crystal
                // float b = twoBalls(p);
                float3 q = p;
                float scale = 0.71; //0.71 is just a magic number i guess
                q.xz /= scale;
                float l = lightning(p)*scale;
                t = opSmoothUnion(l, c, 0.02);
                // t = min(l, c);
                // t = opSmoothUnion(c,o,_Slide2);
                // return o;
                // return l;
                return t;
            }

            // creates the individual bars of the cage.
            float bar (float3 p){
                float3 bp = p;
                // float scale = 1.0 - smoothstep(-.5,-.25,bp.y)*smoothstep(.5,.25,bp.y);
                // scale = lerp(_Slide,_Slide2,scale);
                // bp.xz *= scale;
                float b = box( bp, float3(1,1,1) );
                // b /= scale;
                return b;
            }

            // creates the frame for the cage
            float cage (float3 p){
                // create the lantern frame
                float3 cp = p-float3(0,0,0);    // set the position of the cage position
                float pumpAmt = smoothstep(-.5,-.25,cp.y)*smoothstep(.5,.25,cp.y);
                float scale = lerp(7,30., pumpAmt);
                cp.xz = mul(Rot(smoothstep(-.5,.5,cp.y)*PI), cp.xz);                                // rotates the bars about y-axis
                cp.xz = abs(cp.xz);                                                                 // mirrors bars on xz-plane
                cp.xz -= .2*abs(sin(cp.y+(PI/2)))*smoothstep(-.7,0.,cp.y)*smoothstep(.7,0.,cp.y);   // moves the x back to make that bell curve of the cage
                cp.xz = mul(Rot(smoothstep(-.4,.4,cp.y)*2*PI+_Time[1]), cp.xz);                     // spindels bars
                cp.xz *= scale;
                float b = bar(cp);
                b /= scale;
                b /= sqrt(2);
                return b;
            }

            // creates the "container" so we don't see uglies
            // TODO: definitely get rid of this, replace with a fog at a later point.
            float container(float3 p){
                float3 cp = p;
                float c = circle(cp, 5.);
                c = abs(c)-.1*.2; // shell
                return c;
            }

            // Map all the shapes and shit for your shader here.
            float MapMarch(float3 p){
                // make a spherical container
                float co = container(p);

                float l = cage(p);

                // create the intersecting object                
                // float s = sliceBox(p);

                // create the inside of the staff
                float i = innerCage(p);


                float t = opSmoothUnion(l,i,0);
                // t = min(co,t);
                // return i;
                return t;
                // return min(l,c);
                // return opIntersection(s,l);
                // return min(t,b);
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
                // if(p.y<.01 && d<length(lightPos-p)) dif *= .5;
                
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
                    discard;
                } else {
                    float3 p = ro + rd*d;
                    float3 n = GetLight(p);
                    // n= GetNormal(p);
                    col.rgb = n;
                    // col.rgb = 1;
                }
                return col;
            }
            ENDCG
        }
    }
}
