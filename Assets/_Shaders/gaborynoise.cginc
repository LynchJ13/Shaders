// variant of https://shadertoy.com/view/3tSBRG
// variant of https://shadertoy.com/view/3lSfWW
// inspired from https://shadertoy.com/view/WtBBD1

float A = .2, // Anisotropy. 1 = isotropic
      D = 0., // favorite dir
  phase = 0.,
 phaseY = 0.,
      K = 0.; // seed for random numbers
//#define D atan((p).y,(p).x)

  #define C(x)       ( .5+.5*cos(3.14* (x) ) )
  #define cross(a,b) ( (a).x*(b).y - (a).y*(b).x )
//#define rot(a)       mat2( cos( a + vec4(0,11,33,0) ) )
  #define hash(p,K)    frac(sin(dot(p+K, float2(12.9898, 78.233))) * 43758.5453)
//#define hash2(p)   ( 2.* fract( sin( (p) * mat2(127.1,311.7, 269.5,183.3) ) *43758.5453123 ) - 1. )
  #define hash2(p)     cos( A/2.*6.28*hash(p,K) + float2(0,11) + D + V(p)*_Time[1] ) // variant of random gradient + rotating (= lownoise)
//#define l(i,j)       dot( hash2(I+vec2(i,j)) , F-vec2(i,j) )       // random wavelet at grid vertex I+vec2(i,j) 

  #define wave(v,x,f)  cos( 6.28*( 2.*dot(x,v) + f ) )
//#define Gabor(v,x,f) wave(v,x,f) * exp(-.5*1.*dot(x,x) )
//                     wave        *       ~Gaussian                        * structuring the gaussian / normalization of this ( see https://www.desmos.com/calculator/jejjp1xikd )
//#define Gabor(v,x,f) wave(v,x,f) * C(dot(x,v))  *step(abs(dot(x,v))  ,1.) * C(dot(x,v)  -phaseY) / (.25 + C(phaseY)/2.)
  #define Gabor(v,x,f) wave(v,x,f) * C(cross(x,v))*step(abs(cross(x,v)),1.) * C(cross(x,v)-phaseY) / (.25 + C(phaseY)/2.)

  #define l(i,j)       Gabor( hash2(I+float2(i,j)), F-float2(i,j) , phase + hash(I+float2(i,j),2.))       // random wavelet at grid vertex I+vec2(i,j) 
  #define L(j,x)       lerp( l(0,j), l(1,j), x )

  #define V(p)         0.                           // flownoise rotation speed 
//#define V(p)       ( 2.*mod((p).x+(p).y,2.)- 1. ) // checkered rotation direction 
//#define V(p)         length(p)
//#define V(p)       ( 8. - length(p) )

float GaboryPerlin(float2 p) {
    float2 I = floor(p), 
         F = frac(p), 
     //  U = F;
     //  U = F*F*(3.-2.*F);                   // based Perlin noise
         U = F*F*F*( F* ( F*6.-15.) + 10. );  // improved Perlin noise ( better derivatives )
    return lerp( L(0,U.x) , L(1,U.x) , U.y );  // smooth interpolation of corners random wavelets
}

float layer(float2 U) {
#if 0
    float v = GaboryPerlin( U );              // only 1 kernel
#else
    float v = 0., N = 4.;
    for ( float i = 0.; i < 5.; i++, K+=.11 ) // sum N kernels
        v += GaboryPerlin( U ); 
    v /= 2.*sqrt(N);
    v *= lerp(127./80.,127./50.,A)/2.; // try to regularize std-dev
#endif 
    return v;
}

float cascade(float2 U) {  // --- regular additive cascade
    float v = 0., s = .5, A0=A;
    U += 100.;
    for (int i=0; i<5; i++)
     // A = mix(1.,A0,1.-.5*float(i)/4.), // octave-dependent anisotropy
        v += layer(U)*s, U*=2., s/=2.;
    return v;
}

float mul_cascade(float2 U) { // --- multiplicativ cascade
    float v = 1., A0=A;
    U += 100.;
    for (int i=0; i<5; i++)
     // A = mix(1.,A0,1.-.5*float(i)/4.), // octave-dependent anisotropy
        v *= 1.+layer(U), U*=2.;
    return v;
}

/* void mainImage( out vec4 O, vec2 u )
{
    vec2 R = iResolution.xy,
         S = 8. / R.yy,
         U = ( 2.*u - R ) * S, I = floor(U);
    
    A = 0.;   // anisotropy
    D = 6.28* cos(u.x/R.y+.3*iTime) * cos(u.y/R.y-.2*iTime); // fiber direction
 // phase  = iTime;  // phase, along the Gabor field direction 
 // phaseY = iTime;  // orthophase, along the front direction
    
    U = U/8.;
    float v = iMouse.z <= 0. 
        ? .5 + .5* cascade(U)
        : mul_cascade(U) / 3.;
    
 // v *= .01/fwidth(v);
    O = v * vec4(2,1.3,1,1); // coloring
 } */