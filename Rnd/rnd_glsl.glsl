#version 300 core

in vec4 in_Colour;
in vec2 in_TexCoords;
out vec4 frag_FragColour;
uniform sampler2D u_Texture;

void main() {
    vec2 x = fwidth(in_TexCoords);
    vec2 y = dFdx(in_TexCoords);
    vec2 z = dFdy(in_TexCoords);
    vec2 w = vec2(textureSize(u_Texture, 0));
    vec2 q = w * vec2(2);
}

