module torch_module
    use iso_c_binding
    implicit none

    interface
        subroutine run_torch_model(input_array, input_size, output_array, output_size) bind(C)
            import :: c_int, c_float
            integer(c_int), value :: input_size, output_size
            real(c_float), intent(in)  :: input_array(input_size)
            real(c_float), intent(out) :: output_array(output_size)
        end subroutine run_torch_model
    end interface

contains
    subroutine call_torch()
        integer, parameter :: num_atoms = 10
        real(c_float), dimension(3*num_atoms) :: input_array
        ! 出力サイズは: エネルギー(1) + 力(3*num_atoms)
        real(c_float), dimension(1 + 3*num_atoms) :: output_array
        integer(c_int) :: input_size, output_size
        integer :: i

        input_size = 3 * num_atoms
        output_size = 1 + 3 * num_atoms

        ! 入力データを初期化 (例: ランダムな座標)
        do i = 1, num_atoms
            input_array(3*(i-1)+1) = 0.1 * i      ! x座標
            input_array(3*(i-1)+2) = 0.2 * i      ! y座標
            input_array(3*(i-1)+3) = 0.3 * i      ! z座標
        end do

        ! C++ の関数を呼び出す
        call run_torch_model(input_array, input_size, output_array, output_size)

        ! 結果を出力
        print *, "Energy:", output_array(1)
        print *, "Forces:"
        do i = 1, num_atoms
            print *, "Atom", i, ":", output_array(2+3*(i-1):4+3*(i-1))
        end do
    end subroutine call_torch
end module torch_module

