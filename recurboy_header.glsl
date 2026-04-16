// shader type: gen
precision mediump float;
varying vec2 tcoord;
uniform sampler2D tex;
uniform sampler2D tex2;
uniform vec2 tres;
uniform vec4 fparams;
uniform ivec4 iparams;
uniform float ftime;
uniform int itime;

#define u_time (float(itime) + ftime)
#define u_resolution tres
#define u_x0 fparams[0]
#define u_x1 fparams[1]
#define u_x2 fparams[2]
#define u_x3 fparams[3]
