#version 300 core

in vec2 in_TexCoord;
uniform sampler2D u_Texture;
out vec4 out_FragColour;

void main() {
    out_FragColour = texture(u_Texture, in_TexCoord);
}

