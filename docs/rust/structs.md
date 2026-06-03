# C++ bindings for Rust structs

A Rust `struct` is mapped to a C++ `class`/`struct` with the same fields. If any
field cannot be represented in C++, the struct itself will still have bindings,
but [the relevant field will be private](#opaque_fields).

To receive C++ bindings, the `struct` must be movable in C++. See
[Movable Types](movable_types.md).

## Example

Given the following Rust module:

```
{{ #include ../../examples/rust/struct/example.rs }}
```
<!--  class:Struct -->


Crubit will generate the following bindings:

<!-- Note: Kythe currently indexes this as class `CRUBIT_INTERNAL_RUST_TYPE` because it doesn't have a build rule. -->

```
{{ #include ../../examples/rust/struct/example_generated.h }}
```
<!--  class:CRUBIT_INTERNAL_RUST_TYPE|Struct -->


## Fields {#fields}

The fields on the C++ class are the corresponding Rust types:

*   If the Rust field has [primitive type](../types/primitive.md), then the C++
    field uses the corresponding C++ type.
*   Similarly, if the Rust field has [pointer type](../types/pointer.md), then
    the C++ field has the corresponding C++ pointer type.
*   If the field has a user-defined type, such as a struct or [enum](enums.md),
    then the bindings for the function use the bindings for that type.

### Unsupported fields {#opaque_fields}

Fields that do not receive bindings are made private, and replaced with an
opaque blob of maybe-uninitialized bytes, as well as a comment in the generated
source code explaining why the field could not receive bindings. For example,
since `String` is not supported, the space of the object occupied by a `String`
field will instead be this opaque blob of bytes:

```rust {.bad}
// Rust: `my_field` is some unsupported type, such as `String`
pub my_field: String,
```

```c++ {.bad}
// C++: `my_field` becomes `private`, and its type is replaced by bytes.
private: unsigned char my_field[24]
```

Specifically, the following subobjects are hidden and replaced with opaque
blobs:

*   Non-public fields (`private` or `pub(...)` fields).
*   Fields that implement `Drop`.
*   Fields whose type does not have bindings.
*   Fields that have an unrecognized or unsupported attribute.

## C++ movable {#cpp_movable}

To receive C++ bindings, the `struct` must be movable in C++. See
[Movable Types](movable_types.md).

## `CRUBIT_INTERNAL_RUST_TYPE` annotation {#crubit_internal_rust_type}

You may notice that the generated C++ structs are annotated with the
`CRUBIT_INTERNAL_RUST_TYPE` macro. This annotation instructs Crubit
(specifically `rs_bindings_from_cc`) to disable automated bindings for this C++
type, and instead map all C++ uses of the type back to the existing Rust type.
This ensures that a Rust struct passed to C++ and then back to Rust resolves to
the original Rust type rather than a newly generated one.

While Crubit generates this annotation automatically for Rust-to-C++ bindings,
you can also apply it manually on your own C++ types if you want them to map to
an existing Rust type:

```c++
struct CRUBIT_INTERNAL_RUST_TYPE("char") char_ {
    std::uint32_t c;
};
```

### Template Arguments and Interpolation

For C++ templates, you can use `{}` interpolation syntax within the Rust type
string to substitute template arguments:

```c++
template <typename T>
struct CRUBIT_INTERNAL_RUST_TYPE("RustType<{}>", T) CppType {
    T* value;
};
```

This ensures that a C++ instantiation like `CppType<int>` maps correctly to
`RustType<i32>` in Rust.

Importantly, this interpolation syntax allows you to express Rust generic
parameters that have no direct C++ equivalent, such as lifetimes or default
generic arguments. For example:

```c++
template <typename T>
struct CRUBIT_INTERNAL_RUST_TYPE("RustType<'static, {}>", T) CppType {
    T* value;
};
```

Const generics arguments can also be provided with
`crubit::rust_type::Const<N>`:

```c++
template <typename T>
struct CRUBIT_INTERNAL_RUST_TYPE(
    "RustType<'static, {}, {}>",
    T,
    crubit::rust_type::Const<123>,
) CppType {
    T* value;
};
```
