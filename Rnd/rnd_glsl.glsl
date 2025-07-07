#version 300 core

in vec2 in_TexCoord;
out vec4 frag_FragColour;
uniform float u_iTime;
uniform vec2 u_iResolution;
uniform sampler2D u_iChannel0;
uniform sampler2D u_iChannel1;
uniform sampler2D u_iChannel2;
uniform sampler2D u_iChannel3;

vec4 getUV() {
    return gl_FragCoord / vec4(u_iResolution.xy, 0.0, 1.0);
}

void main() {
    vec4 uv = getUV();
    vec3 col = vec3(0.5) + vec3(0.5) * cos(vec3(u_iTime) + uv.xyx + vec3(0, 2, 4));
    frag_FragColour = vec4(col.xyz, 1.0);
}

