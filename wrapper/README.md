## Converting PyTorch Models to TorchScript for Fortran Integration

This folder demonstrates how to convert PyTorch models to TorchScript format and call them from Fortran code through a C++ wrapper.

## PyTorch Model Conversion

- `traced_force_model.py`: Defines a force field model and converts it to TorchScript format

```
$ python traced_force_model.py
$ ls
traced_force_model.py
```

## Compiling C++ wrapper

The C++ wrapper needs to be compiled as a shared library that can be linked with Fortran code:

- `torch_wrapper.cpp`: C++ wrapper file that provides an interface for loading PyTorch TorchScript models and making them callable from Fortran code. This file handles data conversion between PyTorch tensors and Fortran arrays.
- `CMakeLists.txt`: CMake configuration file that sets up the build process for the C++ wrapper, locates the PyTorch libraries, and configures the compilation of the shared library.

```
$ mkdir build
$ cd build
$ cmake -DCMAKE_PREFIX_PATH=~/tmp/libtorch ..
$ cmake --build .
$ ls
libtorch_wrapper.dylib
$ cd ../
```

## Compiling and runnig FORTRAN interface

- `torch_main.f90`: Main Fortran program that calls the PyTorch model through the interface
- `torch_interface.f90`: Fortran module that provides the interface to the C++ wrapper, handling data conversion between Fortran arrays and the C++ layer

```
$ gfortran -o torch_test torch_interface.f90 torch_main.f90 -L./build -ltorch_wrapper -I./build
$ DYLD_LIBRARY_PATH=./build:/opt/homebrew/opt/libomp/lib:$DYLD_LIBRARY_PATH ./torch_test
```
