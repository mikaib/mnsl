#version 300 core

in vec4 in_Colour;
in vec2 in_TexCoords;
flat in int in_texId;
out vec4 frag_FragColour;
uniform sampler2D u_Texture[16];

void main() {
    vec2 x = vec2(2) / vec2(textureSize(u_Texture[in_texId], 0));
}

