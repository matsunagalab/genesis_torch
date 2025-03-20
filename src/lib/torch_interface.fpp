module torch_interface_mod
    use iso_c_binding
    implicit none

    private
    public :: load_torch_model
    public :: unload_torch_model
    public :: run_torch_model

    interface
        subroutine load_torch_model() bind(C)
        end subroutine load_torch_model

        subroutine unload_torch_model() bind(C)
        end subroutine unload_torch_model

        subroutine run_torch_model(input_array, input_size, output_array, output_size) bind(C)
            import :: c_int, c_float
            integer(c_int), value :: input_size, output_size
            real(c_float), intent(in)  :: input_array(input_size)
            real(c_float), intent(out) :: output_array(output_size)
        end subroutine run_torch_model
    end interface

    public :: evaluate_torch_model

contains
    ! ユーザーフレンドリーなラッパー
    subroutine evaluate_torch_model(coords, natoms, energy, forces)
        real(kind=8), intent(in) :: coords(3,*)
        integer, intent(in) :: natoms
        real(kind=8), intent(out) :: energy
        real(kind=8), intent(out) :: forces(3,*)
        
        real(c_float), allocatable :: coords_flat(:)
        real(c_float), allocatable :: output_array(:)
        integer :: i, j, idx
        
        ! 座標をC形式の1次元配列に変換
        allocate(coords_flat(3*natoms))
        idx = 1
        do i = 1, natoms
            do j = 1, 3
                coords_flat(idx) = real(coords(j,i), c_float)
                idx = idx + 1
            end do
        end do
        
        ! 出力用の配列を確保
        allocate(output_array(1 + 3*natoms))
        
        ! C++関数を呼び出し
        call run_torch_model(coords_flat, 3*natoms, output_array, 1 + 3*natoms)
        
        ! 結果をFortran形式に変換
        energy = real(output_array(1), kind=8)
        
        ! 力を3x3の配列に戻す
        idx = 2
        do i = 1, natoms
            do j = 1, 3
                forces(j,i) = real(output_array(idx), kind=8)
                idx = idx + 1
            end do
        end do
        
        ! メモリ解放
        deallocate(coords_flat)
        deallocate(output_array)
    end subroutine evaluate_torch_model
end module torch_interface_mod
