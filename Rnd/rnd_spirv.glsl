#version 450

uniform float u_iTime;
uniform vec2 u_iResolution;
uniform sampler2D u_iChannel0;
uniform sampler2D u_iChannel1;
uniform sampler2D u_iChannel2;
uniform sampler2D u_iChannel3;

layout(location = 0) in vec2 in_TexCoord;
layout(location = 1) out vec4 out_FragColour;

void main()
{
    vec4 uv = gl_FragCoord / vec4(u_iResolution.xy, 0.0, 1.0);
    vec3 col = vec3(0.5) + (vec3(0.5) * cos((vec3(u_iTime) + uv.xyx) + vec3(float(0), float(2), float(4))));
    out_FragColour = vec4(col.xyz, 1.0);
}

