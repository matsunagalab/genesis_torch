#include <torch/script.h>
#include <iostream>
#include <vector>
#include <cstring>

extern "C" {
    void run_torch_model(float* input_array, int input_size, float* output_array, int output_size) {
        try {
            // TorchScript モデルをロード
            torch::jit::script::Module module = torch::jit::load("traced_force_model.pt");

            // 入力データを PyTorch のテンソルに変換 - ForceModel は [batch_size=1, num_atoms, 3] の形式を期待
            int num_atoms = input_size / 3;
            torch::Tensor input_tensor = torch::from_blob(input_array, {1, num_atoms, 3});
            std::vector<torch::jit::IValue> inputs;
            inputs.push_back(input_tensor);

            // モデルを実行して出力を取得
            auto output = module.forward(inputs).toTuple();
            
            // エネルギーを取得
            at::Tensor energy_tensor = output->elements()[0].toTensor();
            
            // 力を取得
            at::Tensor forces_tensor = output->elements()[1].toTensor();
            
            // PyTorchテンソルのデータをFortranに渡す方法について
            // ISO_C_bindingを使ってFortran側からC++のメモリを参照することは技術的には可能ですが、
            // 問題はPyTorchテンソルのライフタイム管理です
            
            // 現在の実装（コピー方式）:
            // 最初のfloatにエネルギー値を格納
            *output_array = *energy_tensor.data_ptr<float>();
            
            // 残りの部分に力の値をコピー
            std::memcpy(output_array + 1, forces_tensor.data_ptr<float>(), (output_size - 1) * sizeof(float));
            
            // 注: 参照方式を実装するには、テンソルをグローバルに保持するか、
            // 明示的にメモリを解放するコールバック関数をFortranに提供する必要があります。
            // そうしないと、この関数を抜けた時点でテンソルが破棄され、
            // Fortran側が無効なメモリを参照することになります。

        } catch (const c10::Error& e) {
            std::cerr << "Error loading or running the model: " << e.what() << std::endl;
        }
    }
}

