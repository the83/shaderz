precision mediump float;
varying vec2 tcoord;
uniform sampler2D tex;
uniform sampler2D tex2;
uniform vec2 tres;
uniform vec4 fparams;
uniform ivec4 iparams;
uniform float ftime;
uniform int itime;

float u_time = float(itime) + ftime;
vec2 u_resolution = tres;
float u_x0 = fparams[0];
float u_x1 = fparams[1];
float u_x2 = fparams[2];
float u_x3 = fparams[3];
