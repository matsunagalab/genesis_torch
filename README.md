## genesis-2.1.5 からPyTorchモデルを読み込んで力の計算をできるようにする

おおまかな流れ

1. PyTorchモデル(`*.pt`ファイル)を作成する
2. C++ wrapper(`torch_wrapper.cpp`をビルドした共有ライブラリ)を作成する
3. GENESISをコンパイルする
4. GENESISのctrl fileのRESTRAINTSセクションを設定する

### PyTorchモデルを作成する

```bash
# PyTorchモデル(*.ptファイル)を作成する
# クローンする
$ git clone https://github.com/matsunagalab/genesis_torch.git
$ cd genesis_torch/
# Pythonの仮想環境を作成する(ここではuvを使用する)
$ uv venv --python=python3.10
$ source .venv/bin/activate
$ uv pip install -r requirements.txt
# PyTorchモデルを作成する
$ cd wrapper/
$ python traced_force_model.py # traced_force_model.ptが作成される
```

### C++ wrapperを作成する

```bash
# torch_wrapper.cpp をビルドして共有ライブラリを作成する
$ cd genesis_torch/wrapper/
$ mkdir build
$ cd build
$ cmake -DCMAKE_PREFIX_PATH=/path/to/libtorch ..
$ make --build .  # torch_wrapper.{dylib,so}が作成される
```

ちなみにここでは不要だがテスト用にFortranのドライバコードをビルド&実行できる
```bash
$ cd genesis_torch/wrapper/
$ gfortran -o torch_test torch_interface.f90 torch_main.f90 -L./build -ltorch_wrapper -I./build
# Macで実行の場合
$ DYLD_LIBRARY_PATH=./build:/opt/homebrew/opt/libomp/lib:$DYLD_LIBRARY_PATH ./torch_test
# Linuxで実行の場合
$ LD_LIBRARY_PATH=./build:$LD_LIBRARY_PATH ./torch_test
```

### GENESISをコンパイルする

```bash
$ cd genesis_torch/
$ ./configure --enable-pytorch --with-torch-wrapper=/path/to/genesis_torch/wrapper/build
$ make install
```

### GENESISのctrl fileのRESTRAINTSセクションを設定する

```bash
$ cd genesis_torch/atg13/3_production/
# PyTorchモデルを同じフォルダへコピーする。ファイル名は `traced_force_model.pt` としている。
$ cp ../..//wrapper/traced_force_model.pt .
# run.inp が通常のctrlファイル。run_troch.inpがそれにPyTorchを呼び出すRESTRAINTSセクションを足したもの。
# run.inpの実行
$ mpirun -np 8 /path/to/genesis_torch/bin/atdyn run.inp
# run_torch.inpの実行 (Macの場合)
$ DYLD_LIBRARY_PATH=../../wrapper/build:/opt/homebrew/opt/libomp/lib:/path/to/libtorch/lib:$DYLD_LIBRARY_PATH mpirun -np 8 /path/to/genesis_torch/bin/atdyn run_torch.inp
# run_torch.inpの実行 (Linuxの場合)
$ LD_LIBRARY_PATH=../../wrapper/build:/path/to/libtorch/lib:$LD_LIBRARY_PATH mpirun -np 8 /path/to/genesis_torch/bin/atdyn run_torch.inp
```

RESTRAINTSセクションの中身は以下の通り

```Fortran
$ cat run_torch.inp
〜略〜
[SELECTION]
group1              = all

[RESTRAINTS]
nfunctions    = 1
function1     = TORCH  # これでPyTorchモデルを読み込むようになる。run_torch.inpと同じフォルダの `traced_force_model.pt` ファイルを読み込む。
constant1     = 1.0    # PyTorchモデルが返したforceに対して係数 constant1 = 1.0 をかける。
select_index1 = 1      # 力を計算するatom selectionの番号
```
