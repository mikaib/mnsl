## MNSL API Usage
The API is very straight forward, you simply import `mnsl.MNSL` and create a context from source.
After you've created a context you can emit other shader languages with a specified config. Below you will see an example on how to load from a file and emit GLSL 300 ES:
```hx
import mnsl.MNSL;
import mnsl.MNSLContext;
import mnsl.glsl.MNSLGLSLVersion;

class Main {

    public static function main() {
        var shader: MNSLContext = MNSL.fromFile("my_shader.mns");
        var glsl: String = shader.emitGLSL({
            version: GLSL_VER_300_ES
        });

        trace(glsl);
    }

}
```
The options for glsl can be found in `Source/mnsl/glsl/MNSLGLSLConfig.hx`.
Note that these options are language specific and may not be available for other languages.

## Printers
Printers are used to output shader code based on the typed AST of MNSL.
Currently the following prints are available:
- GLSL (`mnsl.glsl.MNSLGLSLPrinter`)

## Main Function
Every shader should contain a main function, this is the entry point of the shader.
The main function is defined as follows:
```mns
func main() {
    // ... shader code ...
}
```

Currently there is no way to define multiple main functions depending on the type of shader.

## Defines
MNSL has support for defines.
```mns
@define(MAX_LIGHTS, 10)
@define(PI, 3.141592653589793)
```

Within code it will work like a read-only variable defined in the top-level scope.
Additionally defines may be used within input, output and uniform tags.
```mns
@define(MAX_LIGHTS, 10)
@uniform(lightPos: Vec3[MAX_LIGHTS])
```

You may also store code in defines, for example:
```mns
@define(PI, 3.141592)
@define(SIN_PI, sin(PI))

func main() {
    return SIN_PI;
}
```
Do note how the order of defines is not important, you may define `PI` after `SIN_PI` and it will still work as expected.

## Inputs, Outputs and Uniforms
Inputs is what your shader will receive from the outside world, outputs is what your shader will output to the outside world and uniforms are variables that are shared between shaders.
These tags **must** be given a type. Also note that these different tag types can share the same name, depending on the printer the actual names may be modified slightly.

```
@input(Position: Vec3)
@input(Colour: Vec3)
@output(Colour: Vec4)

func main() {
    output.Position = input.Position;
    output.Colour = input.Colour;
}
```

Depending on your configuration some inputs or outputs may be pre-defined for you.

## Functions
A function can be defined as follows:
```mns
func someFunction() {}
```
Given parameters:
```mns
func someFunction(x, y) {}
```

Given an explicit type for the parameters:
```mns
func someFunction(x: Float, y: Int) {}
```

And given an explicit return type:
```mns
func someFunction(x: Float, y: Int): Vec3 {}
```

The main restriction of functions is that you cannot recursively call functions. 
Also note that calling a function before it is defined is not allowed.

## Variables
Variables are pretty basic in MNSL, there are 4 valid ways to define a variable:
```mns
var x;
var x: Int;
var x = 5;
var x: Int = 5;
```

They can later be assigned using
```mns
x = 10;
```

And accessed using
```mns
x;
```

### Compile time variables
Some variables are only accessible at compile time, these are read-only and cannot be passed to other functions.

### Struct access
In some cases a variable may be a struct type. You can access the fields of a struct using the dot operator:
```mns
// considering someValue is a Vec2
myStruct.someValue.x
```
Vectors are internally represented as structs with some extra rules regarding their usage.

### Array access
Buffers can be accessed using the square bracket operator:
```mns
// considering someBuffer is a Vec3[10]
someBuffer[0] = { 1.0, 2.0, 3.0 };

var index = 0;
someBuffer[index].x = 1.0;
```

## Comments
MNSL only supports single line comments, these are defined using `//`:

## Typing
### Types
#### Built-in
MNSL has a set of built-in types that are used throughout the language. Below a list of types from the source code:
```hx
public static var TUnknown(get, never): MNSLType;
public static var TString(get, never): MNSLType;
public static var TBool(get, never): MNSLType;
public static var TVoid(get, never): MNSLType;
public static var TFloat(get, never): MNSLType;
public static var TInt(get, never): MNSLType;
public static var TMat2(get, never): MNSLType;
public static var TMat23(get, never): MNSLType;
public static var TMat24(get, never): MNSLType;
public static var TMat3(get, never): MNSLType;
public static var TMat32(get, never): MNSLType;
public static var TMat34(get, never): MNSLType;
public static var TMat4(get, never): MNSLType;
public static var TMat42(get, never): MNSLType;
public static var TMat43(get, never): MNSLType;
public static var TVec2(get, never): MNSLType;
public static var TVec3(get, never): MNSLType;
public static var TVec4(get, never): MNSLType;
public static var TSampler(get, never): MNSLType;
public static var TCubeSampler(get, never): MNSLType;
public static var TCTValue(get, never): MNSLType;

public static function Template(T: String): MNSLType {
    return new MNSLType('Template<$T>', true);
}
```

#### Vectors
Vectors are a first-class citizen in MNSL, they are used to represent points in space, colors and other data.
You can define a vector with `VecN` where `N` is the number of components in the vector.
Vectors are limited to being floating point numbers!

#### Matrices
Matrices are also a first-class citizen in MNSL, they are used to represent transformations in space.
You can define a matrix with `MatNM` or `MatN` where `N` is the number of rows and `M` is the number of columns in the matrix.
Note that N may not equal M when using the format `MatNM`, use `MatN` for those.

#### Strings
While MNSL supports parsing strings and typing them, it should only be used for compile-time functions.

#### TCTValue
`TCTValue` is a bit special as it is a type reserved for compile-time structs. Structs with this type cannot be passed as function arguments and can also not be assigned to other values or itself.

#### Buffers
For inputs, outputs and uniforms you can define the type to be a buffer. An example of this is:
```
@input(x: Float[10])
```

Note that you must explicitly define the size of the buffer.
You may additionally use defines for the size of the buffer, for example:
```
@define(MAX_LIGHTS, 10)
@uniform(uLightPos: Vec3[MAX_LIGHTS])
```

### Explicit Typing
In many cases you can explicitly define the type of something, below are valid cases:
- Function Return Types (`func test(): Int {}`)
- Function Parameters (`func test(x: Int) {}`)
- Variable Declarations (`let x: Int = 5`)
- Inputs, outputs or uniforms (`@input(x: Int)`)

#### Required explicit typing
Whenever you define points of interaction between your code or different shaders you are required to explicitly type the data.
This currently applies to the following:
- Inputs (`@input`)
- Outputs (`@output`)
- Uniforms (`@uniform`)

### Inference
In most cases MNSL can infer the type of a variable, parameter or return value.
```
func test(x) {
    return x;
}

func main() {
    var v: Float;
    var q = test(v);
    test(q);

    return q;
}
```

The order in the above sample is as follows:
- Function `test` defined with a parameter of `TUnknown` and returns `TUnknown`.
- The return type of `test` will be connected to the type of the parameter `x`.
- Main gets defined with no parameters and returns `TUnknown`.
- `var v` is explicitly defined as `TFloat`
- `var q` is defined and connected to the return value of `test`, as the input to `test` is a `TFloat` it will also mark the parameter `x` as `TFloat` with the consuquence that the return value of `test` is also `TFloat`. This means that `var q` is also a `TFloat`.
- `test` is called with `q` as the parameter, which is valid.
- We return `q`, which is a `TFloat`. The return type of `main` is inferred to be `TFloat`.

### Generics
Generics are a way to define functions that can be used with different types. These are currently reserved for internal use only. 
An example is the `sin(x: T): T` function, which is internally defined as:
```hx
{
    name: "sin",
    args: [
        { 
            name: "value", 
            type: MNSLType.Template("T") 
        }
    ],
    returnType: MNSLType.Template("T")
}
```
When calling a templated function it will create brand new types for every template, set them to `TUnknown` and connect them together using constraints.
Generally speaking, generics in MNSL is very limited.

### Casting
#### Implicit Casting of Vectors
Any type of vector may be implicitly cast to another `VecN` type.
The behaviour is as follows:
- When the current value is cast to a vector of a smaller size is it truncated.
- When the current value is cast to a vector of a larger size z is set to 0.0 and w to 1.0 (if either applies)

Examples:
- vec2(2.0, 3.0) -> vec3(2.0, 3.0, 0.0)
- vec2(2.0, 3.0) -> vec4(2.0, 3.0, 0.0, 1.0)
- vec4(1.0, 2.0, 3.0, 4.0) -> vec3(1.0, 2.0, 3.0)
- vec4(1.0, 2.0, 3.0, 4.0) -> vec2(1.0, 2.0)

A numerical value (`Float` or `Int`) can also be cast to a vector, this will result in a vector with all components set to the value.
Example:
``` 
var a: Vec2 = 1.0; // -> vec2 a = vec2(1.0, 1.0);
var b = a * 2; // -> vec2 b = a * vec2(2.0, 2.0);
```

Another interesting case is with Binary Operators, for example:
```
Vec2 * Vec3 * Vec4
```
MNSL Prefers casting up (vec3->vec4) over casting down and losing information (vec4->vec3), thus the result would be:
```
vec4(vec3(vec2(1, 1), 0.0) * vec3(2, 2, 2), 1.0) * vec4(3, 3, 3, 3)


vec4(
    vec3(
        vec2(1, 1),
    0.0) * vec3(2, 2, 2),
1.0) * vec4(3, 3, 3, 3)
```