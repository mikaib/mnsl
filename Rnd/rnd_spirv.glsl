#version 450

void main()
{
    vec3 v = vec3(float(1));
    vec3 _43 = vec3(float(1), float(2), float(3));
    v = vec3(_43.z, _43.y, _43.x);
}

