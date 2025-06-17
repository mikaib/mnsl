#version 300 core

float test(float x) {
    return (-1.0 + 2.0) * -3.0;
}

float main(float x, vec2 y) {
    return test(3.0);
}

