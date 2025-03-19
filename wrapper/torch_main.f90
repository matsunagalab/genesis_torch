program main
    use torch_module
    implicit none

    print *, "Running Torch Model from Fortran..."
    call call_torch()
    print *, "Finished Running Torch Model."
end program main

