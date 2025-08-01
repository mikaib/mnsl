# MNSL - MaNa Shader Language
MNSL is a shader language designed for use within the Mana Multimedia Framework.
Some design goals of MNSL are:
- Lightweight and dependency free.
- Hackable codebase.
- Easy to use and understand.
- Support for multiple shader languages.

Generally these goals have been met but there are still some areas that need improvement.

## Try it
There is a very basic shadertoy like tool to try out MNSL: https://mki.sh/mnsl.html

## MNSL API Usage
The API is very straight forward, you simply import `mnsl.MNSL` and create a context from source.
After you've created a context you can emit other shader languages with a specified config. Below you will see an example on how to load from a file and emit GLSL 300 ES:
```hx
import mnsl.MNSL;
import mnsl.MNSLContext;
import mnsl.glsl.MNSLGLSLVersion;
import mnsl.spirv.MNSLSPIRVShaderType;
import sys.io.File;

class Main {

    public static function main() {
        var shader: MNSLContext = MNSL.fromFile("my_shader.mns" , {});
        
        if (shader.hasErrors()) {
            trace("Shader has errors: " + shader.getErrors().join("\n"));
            return;
        }
        
        if (shader.hasWarnings()) {
            trace("Shader has warnings: " + shader.getWarnings().join("\n"));
        }
        
        var glsl: String = shader.emitGLSL({
            version: GLSL_VER_300,
            versionDirective: GLSL_CORE
        });

        var spirv: Bytes = shader.emitSPIRV({
            shaderType: SPIRV_SHADER_TYPE_FRAGMENT
        });

        File.saveContent("my_shader.glsl", glsl);
        File.saveBytes("my_shader.spv", spirv);
    }

}
```
The options for glsl can be found in `Source/mnsl/glsl/MNSLGLSLConfig.hx`.
Note that these options are language specific and may not be available for other languages.

## Printers
Printers are used to output shader code based on the typed AST of MNSL.
Currently the following prints are available:
- GLSL (`mnsl.glsl.MNSLGLSLPrinter`)
- SPIR-V (`mnsl.spirv.MNSLSPIRVPrinter`, **NOTE:** *This printer is still experimental and may not work as expected*)

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

## Preprocessor
MNSL Contains a basic preprocessor. 
```mns
#include "pbr.mns"

func main() {
    #if TEST_DEFINE
        return 1.0;
    #else
        return vec2(1.0);
    #end
}
```

By default `#include` will look in the directory of the shader. When loaded from a source string it will look in `./`.
You can set the "root" path using the `rootPath` option:
```hx
var shader: MNSLContext = MNSL.fromFile("my_shader.mns" , {
    rootPath: "/my/root/path"
});
```

If you are running on a non-sys target you may use `MNSL_NO_SYS` to disable the default `#include` implementation.
You can redefine the behaviour of `#include` by using the `preprocessorIncludeFunc` option when creating a Shader. The default implementation is:
```hx
(path: String, root: String) -> {
    #if !MNSL_NO_SYS
        var filePath = haxe.io.Path.join([root, path]);

        if (sys.FileSystem.exists(filePath)) {
            return sys.io.File.getContent(filePath);
        }
        
        return null;
    #else
        return null;
    #end
};
```

You can also create defines for the preprocessor, these will be used to determine which code to include or exclude.
```hx
var shader: MNSLContext = MNSL.fromFile("my_shader.mns" , {
    preprocessorDefines: [
        'TEST_DEFINE'
    ]
});
```

Note that defines and preprocessor defines are not the same thing:
- Preprocessor defines can only be defined using the API and are only true/false.
- Defines can be defined in the shader code (or from the API), can hold any value (including expressions) and can be used as values in your shader code itself.

Currently the preprocessor supports the following directives:
- `#include <path>`: Includes the file at the given path.
- `#if <condition>`: If the condition is true, the code between `#if` and `#end` will be included.
- `#else`: If the condition is false, the code between `#else` and `#end` will be included.
- `#end`: Ends the current `#if` or `#else` block.

## Optimizer
MNSL is designed to output a very verbose AST, this is done to increase the amount of languages that can be generated from it.
Generally this results in a lot of redundant and inefficient code, so MNSL comes with an optimizer that will try to reduce the amount of code and make it more efficient.
The optimizer is enabled by default but can be disabled by providing an empty array of optimizations to `optimizerPlugins` to the compiler options. Note that not all printers may support every optimization.

Currently MNSL provides the following optimizations:
- `ScalarVectorInit` - This converts `VecN(x, x, x, x)` to `VecN(x)` where `x` is a scalar value.
- `SwizzleAccess` - This converts `VecN(vec.x, vec.y, vec.z)` to `vec.xyz` where `vec` is a vector and `x`, `y`, `z` are the components of the vector.
- `SwizzleAssign` - This converts `vec.x = x; vec.y = y;` to `vec.xy = (x, y);` where `vec` is a vector and `x`, `y` are the components of the vector.

It is important to note that optimizations are stacked on top of each other, so the order in which they are added to the `optimizerPlugins` array matters.

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
Below is when you may use what struct:
- `@input` is used for inputs to the shader, these are read-only and cannot be modified, access with `input.<name>`.
- `@output` is used for outputs from the shader, these are write-only and cannot be read from, access with `output.<name>`.
- `@uniform` is used for uniforms, these are read-write and can be accessed with `uniform.<name>`.

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

Alternatively you can also define functions like:
```mns
func fsquared(x) x * x;
func fsquared(x: Float) x * x;
func fsquared(x: Float): Float x * x;
func fsquared(x) -> x * x;
func fsquared(x: Float) -> x * x;
func fsquared(x: Float): Float -> x * x;
```

### Restrictions
The main restriction of functions is that you cannot recursively call functions. 
Also note that calling a function before it is defined is not allowed.

### Function inlining
One may use the `inline` keyword to indicate that a function should be inlined.
Note that this is only a hint to the compiler and it may choose to ignore it.
```mns
inline func someFunction(x) -> x;
```

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
someBuffer[0] = (1.0, 2.0, 3.0);

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

You can initialize a vector with the following syntax:
```mns
var v: Vec3 = (1.0, 2.0, 3.0);
```

A scalar value can also be used to initialize a vector, this will result in a vector with all components set to the value:
```mns
var v: Vec3 = 1.0; // -> vec3 v = vec3(1.0, 1.0, 1.0);
```

The `(...)` syntax automatically infers the type of the vector, so you can also use it without explicitly defining the type:
```mns
var v = (1.0, 2.0, 3.0); // -> vec3 v = vec3(1.0, 2.0, 3.0);
var v = (1.0, 2.0); // -> vec2 v = vec2(1.0, 2.0);
```

In some cases you might not want this, so you can also use the `vecN` function to explicitly define the type of the vector:
```mns
var v = vec3(1.0); // -> vec3 v = vec3(1.0, 1.0, 1.0);
```

You can also use other vectors to initialize a vector, this will result in a vector with the same components as the original vector:
```mns
var x = (3, 4);
var y: Vec4 = (1, 2, x); // -> vec4 y = vec4(1, 2, x.x, x.y);
```

You can also initialize an empty vector:
```mns
var a = vec3(); // -> vec3 a = vec3(0.0, 0.0, 0.0);
var b = vec4(); // -> vec4 b = vec4(0.0, 0.0, 0.0, 1.0);
```

Vectors will implitly cast to other vector types using the mask `(0, 0, 0, 1)`, for example:
```mns
var x: Vec2 = (1.0, 2.0);
var y: Vec4 = x; // -> vec3 y = vec3(1.0, 2.0, 0.0, 1.0);
```

And they may also be truncated when casting to a smaller vector type:
```mns
var x: Vec4 = (1.0, 2.0, 3.0, 4.0);
var y: Vec2 = x; // -> vec2 y = vec2(1.0, 2.0);
```

You can access vectors in a few wAYS
```mns
var v = (1.0, 2.0, 3.0);
var x1 = v.x;
var x2 = v[0]; // note: index must be constant int
```

And you may also 
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
Generics are a way to define functions that can be used with different types.
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

You may also limit the types that can be used with a generic parameter by using the limits array.
```hx
{
    name: "sin",
    args: [
        { 
            name: "value", 
            type: MNSLType.Template("T", [
                MNSLType.TFloat, 
                MNSLType.TVec2
            ]),
        }
    ],
    returnType: MNSLType.Template("T")
}
```

In the above case only `Float` or `Vec2` will be accepted as the type for `T`. If you try to use a different type, it will result in an error.
Note that you can still pass in an `Int`, `Vec3` or `Vec4`. If the limits can't be satisfied thru normal means, MNSL will try to cast the type to one of the limits. This means that you can pass in a `Vec3` and it will be cast to a `Vec2` if the function expects a `Vec2`.

You can also create user-defined generics, these are defined as such:
```mns
func identity<T>(x: T): T -> x;
func add<T>(x: T, y: T): T -> x + y;

func main() {
    var x = identity(10) -> add(_, 10);
}
```
There are no constraints on generics. Please note:
- If any parameter type is not explicitly defined, it will be inferred globally.
```mns
func multiplyBy<T>(x: T, y): T -> x * y;

func main() {
    var a = multiplyBy(10, 10); // y will be inferred as Int
    var b = multiplyBy(vec2(10), vec2(10)); // Error: Expected Int but got Vec2 (parameter y) 
}
```

- If the return type is not explicitly defined, the type will be inferred from that specific call (an imaginary `Any` type).
```
func add<T>(x: T, y: Float) -> x * y; // Not explicitly defined.
 
func main() {
    var a = add(10, 10.0); // T is Int, but it will return Float
    var b = add(vec2(10), 10.0); // T is Vec2 and it will return Vec2
}
```

It is recommended to always explicitly define the parameter- and return types of generics to avoid confusion and unexpected behaviour.

### Swizzling
Swizzling is a way to access specific components of a vector.
You can use the dot operator to access specific components of a vector, for example:
```mns
var v: Vec3 = (1.0, 2.0, 3.0);
var x: Float = v.x; // x = 1.0
var y: Float = v.y; // y = 2.0
var z: Float = v.z; // z = 3.0
var allZ: Vec3 = v.zzz; // allZ = (3.0, 3.0, 3.0)
var allB: Vec4 = v.bbbb; // allB = (3.0, 3.0, 3.0, 3.0)
```

Depending on the type of vector you are using, the available swizzle components may differ.
- `x` or `r` for the first component (always available)
- `y` or `g` for the second component (always available)
- `z` or `b` for the third component (available for `Vec3` and `Vec4`)
- `w` or `a` for the fourth component (available for `Vec4`)

You are free to use and mix these swizzle components as you like, for example:
```mns
var v: Vec4 = (1.0, 2.0, 3.0, 4.0);
var q = v.rybw; // same as .rgba or .xyzw
```

You can also set the components of a vector using swizzling, for example:
```mns
var v: Vec4 = (1.0, 2.0, 3.0, 4.0);
v.xz = (5.0, 6.0); // v = (5.0, 2.0, 6.0, 4.0)
v.yw = 1.0; // v = (5.0, 1.0, 6.0, 1.0)
```

### Loops
Loops in MNSL are very similar to other languages, you can use `for` and `while` loops.
```mns
for (init; condition; increment) {
    // ... code ...
}

while (condition) {
    // ... code ...
}
```

For example:
```mns
for (var i = 0; i < 10; i++) {
    // ... code ...
}

while (i < 10) {
    // ... code ...
    i++;
}
```

### Chaining
Chaining is a way to call multiple functions on the same object in a single line.
Consider the following code:
```
var F = fresnelSchlick(max(dot(V, H), 0.0), F0);
```

With chaining you can write this as:
```
var F = V -> dot(_, H) -> max(_, 0.0) -> fresnelSchlick(_, F0);
```

You may chain any expression on both sides of the `->` operator, this includes variables, functions and other expressions.
Here are a few examples:
```mns
var y = x -> squared(_); // squared(x);
var y = 5 + 5 -> 5 + _;  // 5 + 5 + 5;
```

Note that _ will literally replace the `_` in the expression, this means that when you use it together with binary operators, the `_` will not be evaluated first.
```mns
var y = 1 + 2 -> _ * 3;
```
Above you may expect it to evaluate 1 + 2 = 3 first and then multiply it by 3, but it will actually evaluate to `1 + 2 * 3` which is `1 + 6 = 7`.
For this reason it is recommended to use parentheses to make sure the order of operations is correct:

```mns
var y = (1 + 2) -> _ * 3; // -> 9
```

Last but not least, you can use the vector initialization syntax and vector array access to chain multiple values together:
```mns
func squared(x) -> x * x;
func halfOf(x) -> x * 0.5;

func main() {
    var x = 5;
    var y = x -> (squared(_), halfOf(_)) -> _[0] / _[1];
}
```

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

### Todo
- [ ] Language: Ternary (X ? A : B)
- [ ] Language: Pipe operator use `_` for first argument if right-hand expression does not contain `_` 
- [ ] Analyser: Inlined functions
- [ ] Analyser: allow unused functions to have unresolved constraints
- [ ] Analyser: fix IVec2 support (and test it on `textureSize()`)
- [ ] Optimiser: CommonStructBase
- [ ] Optimiser: OptimiseConstExpr
- [ ] Optimiser: Improve test case 1 (see RND folder)
- [ ] Review: Built-ins
- [ ] Review: Positional Data
- [ ] Review: SPIR-V `mod()`
- [ ] Review: SPIR-V attribute names (see now fixed glsl issue)