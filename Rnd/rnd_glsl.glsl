#version 300 core

int test_1() {
    int a = 10000;
    int b = 0;
    if (a == 0) {
        b = 1;
    }
    return b;
}

int test_2() {
    int a = 10000;
    int b = 0;
    if (a == 0) {
        b = 1;
    }
    if (a == 1) {
        b = 2;
    }
    return b;
}

int test_3() {
    int a = 10000;
    int b = 0;
    if (a == 0) {
        b = 1;
    } else {
        if (a == 1) {
            b = 2;
        }
        if (a == 2) {
            b = 3;
        }
    }
    return b;
}

int test_4() {
    int a = 10000;
    int b = 0;
    if (a == 0) {
        b = 1;
    } else {
        if (a == 1) {
            b = 2;
        } else {
            if (a == 2) {
                b = 3;
            } else {
                b = 4;
            }
        }
    }
    return b;
}

int test_5() {
    int a = 10000;
    int b = 0;
    if (a == 0) {
        b = 1;
    } else {
        if (a == 1) {
            b = 2;
        } else {
            if (a == 2) {
                b = 3;
            } else {
                b = 4;
            }
        }
        if (a == 4) {
            b = 5;
        }
    }
    return b;
}

void main() {
    test_1();
    test_2();
    test_3();
    test_4();
    test_5();
}

