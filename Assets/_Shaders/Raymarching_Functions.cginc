#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST 1e-4
#define PI 3.141592658


//
float SmoothBump (float lo, float hi, float w, float x)
{
    return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}

float SmoothValley (float lo, float hi, float w, float x)
{
    return (smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
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

float Fbm1 (float p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int j = 0; j < 5; j ++) {
    f += a * gnoise(p);
    a *= 0.5;
    p *= 2.;
  }
  return f * (1. / 1.9375);
}

float2 Hashv2v2 (float2 p)
{
  float2 cHashVA2 = float2 (37., 39.);
  return frac (sin (float2 (dot (p, cHashVA2), dot (p + float2 (1., 0.), cHashVA2))) * 43758.5453123);
}

float gnoisev2 (float2 p)
{
  float2 t, ip, fp;
  ip = floor (p);  
  fp = frac (p);
  fp = fp * fp * (3. - 2. * fp);
  t = lerp(Hashv2v2 (ip), Hashv2v2 (ip + float2 (0., 1.)), fp.y);
  return lerp (t.x, t.y, fp.x);
}

float Fbm2 (float2 p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int j = 0; j < 5; j ++) {
    f += a * gnoisev2 (p);
    a *= 0.5;
    p *= 2.;
  }
  return f * (1. / 1.9375);
}


float plot(float2 st, float pct){
    return  smoothstep( pct-0.02, pct, st.y) -
            smoothstep( pct, pct+0.02, st.y);
}

/*** Helpful Math Functions ***/
// rotate something by angle a
float2x2 Rot (float a){
    float c = cos(a);
    float s = sin(a);
    return float2x2(c, -s, s, c);
}

/***  Shape/Dist/SDF functions ***/

// Circle @ point p w/ radius r:
float circle(float3 p, float r){
    return length(p)-r;
}

float box(float3 p, float3 b) {
    float3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float torus(float3 p, float2 t){
    float2 q = float2(length(p.xz)-t.x,p.y);
    return length(q) - t.y;
}

float cylinderInf ( float3 p, float3 c){
    return length(p.xz-c.xy)-c.z;
}

float sdOctahedron( float3 p, float s)
{
  p = abs(p);
  return (p.x+p.y+p.z-s)*0.57735027;
}

float PrCylDf (float3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

//TODO: find out why the height and radius seem swapped?
float cylinderCapped( float3 p, float h, float r){
    float2 d = abs(float2(length(p.xz),p.y)) - float2(h,r);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float cylinderCapped ( float3 p, float3 a, float3 b, float r){
    float3 ba = b - a;
    float3 pa = p - a;
    float baba = dot(ba,ba);
    float paba = dot(pa,ba);
    float x = length(pa*baba-ba*paba) - r*baba;
    float y = abs(paba-baba*0.5)-baba*0.5;
    float x2 = x*x;
    float y2 = y*y*baba;
    float d = (max(x,y)<0.0)?-min(x2,y2):(((x>0.0)?x2:0.0)+((y>0.0)?y2:0.0));
    return sign(d)*sqrt(abs(d))/baba;
}

/*** Primitive Alteration Functions ***/

// Exact functions
float elongate(in float3 p, in float3 h){
    float3 q = p - clamp( p, -h, h);
    return torus(q, float2(.4, .1));
}

/*** Primitive Combination Functions ***/

float opUnion (float d1, float d2) { return min(d1,d2); }

float opSubtraction (float d1, float d2) { return max(-d1,d2); }

float opIntersection (float d1, float d2) { return max(d1,d2); }

float opMorph (float d1, float d2, float k){ return lerp(d1,d2,k);}



// float opRep( in float3 p, in float3 c, in sdf3d primitive )
// {
//     vec3 q = mod(p+0.5*c,c)-0.5*c;
//     return primitive( q );
// }

// float morph = mix(
//     length(p-vec3(4,1,2))-1., 
//     dBox(p-vec3(4,1,2), vec3(1,1,1)), 
//     sin(t)*.5+.5
// );
// Smooth variations

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return lerp( d2, d1, h ) - k*h*(1.0-h); }

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return lerp( d2, -d1, h ) + k*h*(1.0-h); }

float opSmoothIntersection( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return lerp( d2, d1, h ) + k*h*(1.0-h); }




/*** Deformations/Distortions ***/
/*float opTwist( float3 p ){
    const float k = 10.0;
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    float2x2 m = float2x2(c,-s,s,c);
    // float3 q = float3(m*p.xz,p.y);
    float3 q = float3(mul(m,p.xz),p.y);
    return cylinderInf(p, float3(0,0,.05));
}*/



/*** M&P Functions */

// Easy Lighting so you no think, ooga
/* float GetLight(float3 p) {
    float3 lightPos = float3(3, 5, 4);
    float3 l = normalize(lightPos-p);
    float3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l)*.5+.5, 0., 1.);
    float d = Raymarch(p+n*SURF_DIST*2., l);
    // if(p.y<.01 && d<length(lightPos-p)) dif *= .5;
    
    return dif;
} */

// Main Raymarching function (Don't actually use this, probably just copy it to whatever shader you're using it in.)
/*
float RaymarchCOPY(float3 ro, float3 rd) {
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
*/