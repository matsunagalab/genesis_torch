module torch_module
    use iso_c_binding
    implicit none

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

    subroutine call_torch_multiple(nstep)
        integer, intent(in) :: nstep
        integer, parameter :: num_atoms = 10
        real(c_float), dimension(3*num_atoms) :: input_array
        ! 出力サイズは: エネルギー(1) + 力(3*num_atoms)
        real(c_float), dimension(1 + 3*num_atoms) :: output_array
        integer(c_int) :: input_size, output_size
        integer :: i, step
        real(c_float) :: total_energy
        real :: start_time, end_time

        input_size = 3 * num_atoms
        output_size = 1 + 3 * num_atoms
        total_energy = 0.0

        ! 入力データを初期化 (例: ランダムな座標)
        do i = 1, num_atoms
            input_array(3*(i-1)+1) = 0.1 * i      ! x座標
            input_array(3*(i-1)+2) = 0.2 * i      ! y座標
            input_array(3*(i-1)+3) = 0.3 * i      ! z座標
        end do

        print *, "Running torch model for", nstep, "steps"
        
        ! 事前にモデルを読み込む
        call load_torch_model()
        
        call cpu_time(start_time)
        
        ! nstep回モデルを実行
        do step = 1, nstep
            ! C++ の関数を呼び出す
            call run_torch_model(input_array, input_size, output_array, output_size)
            
            ! 出力情報の取得と処理
            total_energy = total_energy + output_array(1)
            
            ! 必要に応じて入力データを更新
            do i = 1, num_atoms
                input_array(3*(i-1)+1) = input_array(3*(i-1)+1) + 0.01  ! x座標を少し変更
                input_array(3*(i-1)+2) = input_array(3*(i-1)+2) + 0.01  ! y座標を少し変更
                input_array(3*(i-1)+3) = input_array(3*(i-1)+3) + 0.01  ! z座標を少し変更
            end do
            
            ! 各ステップの情報を出力（オプション）
            if (mod(step, 10000) == 0 .or. step == 1 .or. step == nstep) then
                print *, "Step", step, "Energy:", output_array(1)
            end if
        end do
        
        call cpu_time(end_time)

        ! 最終結果を出力
        print *, "Completed", nstep, "steps in", end_time - start_time, "seconds"
        print *, "Average Energy:", total_energy / nstep
        print *, "Final Forces:"
        do i = 1, num_atoms
            print *, "Atom", i, ":", output_array(2+3*(i-1):4+3*(i-1))
        end do
        
        ! 明示的にモデルをアンロードする場合はこれを呼ぶ
        ! 通常はプログラム終了時に自動的に解放されるので必須ではない
        ! call unload_torch_model()
    end subroutine call_torch_multiple
end module torch_module

