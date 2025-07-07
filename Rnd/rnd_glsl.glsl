#version 300 core

vec2 other_TVec2_RTTVec2(vec2 x) {
    return x;
}

vec2 squared_TVec2_RTTVec2(vec2 x) {
    return other_TVec2_RTTVec2(x);
}

float other_TFloat_RTTFloat(float x) {
    return x;
}

float squared_TFloat_RTTFloat(float x) {
    return other_TFloat_RTTFloat(x);
}

int other_TInt_RTTInt(int x) {
    return x;
}

int squared_TInt_RTTInt(int x) {
    return other_TInt_RTTInt(x);
}

void main() {
    int x = squared_TInt_RTTInt(1);
    float y = squared_TFloat_RTTFloat(1.0);
    vec2 z = squared_TVec2_RTTVec2(vec2(1.0));
}

