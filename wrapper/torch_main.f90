program main
    use torch_module
    implicit none

    print *, "Running Torch Model from Fortran..."
    !call call_torch()
    call call_torch_multiple(100000)
    print *, "Finished Running Torch Model."
end program main

