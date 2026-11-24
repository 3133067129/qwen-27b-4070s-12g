# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## 这个仓库是什么

把 **Ternary Bonsai 2 27B**（底座 Qwen3.8-27B，1.58-bit 三元权重 + Hadamard 旋转基）移植进 **NInfer** 推理引擎，
跑在 RTX 4070 SUPER（Ada / sm_89 / Windows）上。**只发布工具、文档和引擎补丁，不发布权重。**

- `tools/pack.py`：GGUF → `.ninfer` 三元打包器。逐张量映射规则以 `tools/MAPPING.json` 为准。
- `tools/verify/`：制品验证脚本、旋转/GEMM oracle，以及脱离引擎构建树的 nvcc 测试台（`harness/`）。
- `patches/changed-files/`：引擎侧改动。它是**整文件快照，不是 diff**，按相同相对路径覆盖到基座树
  `Ambolio/ninfer-4090-windows` @ `6eb70a07`（v1.0.8 线）。不要换成 v1.2.0 等其它线，那些线的目录结构和格式注册表都不同。
- `docs/`（中文）：01 构建与运行，02 普通模型转换，03 三元移植主线（数学、布局、打包规则），04 坑与验证方法学。

## 本地布局（作者的约定，都被 .gitignore 忽略，不在仓库里）

- `ninfer-4070s-12g/`：引擎源码树 = 基座 `6eb70a07` + 已覆盖的补丁，本身是一个 git 检出。**引擎代码在这里改，也在这里编。**
- `build/b1/`：构建目录，产物在 `build/b1/apps/`（`ninfer.exe`、`ninfer-serve.exe`、`ninfer-perplexity.exe`）。
  本地的配置脚本是 `build/configure_b1.cmd`，构建脚本是 `build/build_b1.cmd`。
- `models/`：权重、`.ninfer` 制品和本地启动脚本。常用的有 `models/Ternary-Bonsai-2-27B/Ternary-Bonsai-2-27B-PQ2_0.gguf`、
  `models/bonsai2_27b_ternary.ninfer`、`models/bonsai_hadamard_meta.json`。

## 补丁包必须与引擎树保持一致

改了 `ninfer-4070s-12g/` 里的文件，要按同一相对路径复制到 `patches/changed-files/`。Python 侧的
`tools/artifact/{numeric,layouts,__init__}.py` 也要复制：三元格式在那里注册，`pack.py` 和 verify 脚本都依赖它。

- 补丁里的每个文件开头都有 3 行 `MODIFIED for the NInfer ternary port …` 声明（Apache-2.0 §4b），新增或修改文件时要保留或补上。
- 自检：`patches/changed-files/` 下每个文件的哈希与引擎树里的对应文件相同；`git -C ninfer-4070s-12g status` 不出现补丁以外的文件。
- 同时更新 `patches/README-改动说明.md`（改动清单和文件数）和 docs/03 §2 的改动表。

## 常用命令

Python 工具需要 numpy 和 torch，还要能 import 引擎树的 `tools.artifact`：用 `--ninfer-root` 或环境变量 `NINFER_ROOT`
指向**已覆盖补丁**的引擎树，或把它放进 `PYTHONPATH`。指向没打补丁的基座时会报 `unknown numeric format: 'PQ2_0_G128'`。

```bash
# 打包器。check 只读，约 2 分钟；build 不会覆盖已存在的输出文件。
python tools/pack.py check        --gguf <gguf> --template <groupwise-int.ninfer> --ninfer-root ninfer-4070s-12g
python tools/pack.py layer3 <out> --gguf ... --template ...   # 只打 frontend + 符号表 + 第 3 层，用于装载冒烟
python tools/pack.py build  <out> --gguf ... --template ...   # 全量。改了 pack.py 必须重打，并用新文件名
# 对应的环境变量：NINFER_TERNARY_GGUF / NINFER_TERNARY_TEMPLATE / NINFER_ROOT

# 制品验证（先设 NINFER_ROOT）。四个合计约一分钟。
python tools/verify/check_signs.py         <art> <meta.json>                 # meta 由 dump_gguf_meta.py <gguf> <out.json> 生成
python tools/verify/check_payload_order.py <art> text/layers/0/gdn/output   # 方案 A：scale 全正，zero_share 0.3278
python tools/verify/check_row_order.py     <art> <gguf>                     # DUPLICATED 0 / MISSING 0
python tools/verify/check_assembly.py      <art> <gguf>                     # "15/15 assembly rules OK"
python tools/verify/list_objects.py        <art> <name-substring>...
```

- **构建引擎**：
  - 先调用 `vcvars64.bat`，再设 `VSLANG=1033`，否则 MSVC 输出中文，会破坏 ninja 的依赖扫描。
  - 配置：`cmake -S <engine> -B build/b1 -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_ARCHITECTURES=89 -DNINFER_BUILD_APPS=ON -DNINFER_BUILD_BENCHMARKS=OFF`。
  - 构建：`ninja -C build/b1 -j 8 -k 0`，以 `BUILD OK` 为准。
  - 带重试和停滞检测的版本是 `tools/verify/buildb1inc2.cmd` 和 `buildb1clean.cmd`，里面的路径是占位符。
- **运行**：
  - 单次问答：`ninfer.exe <art> --prompt "The capital of France is" --max-new 32`。中文 prompt 必须用 `--messages <json>`。
  - 服务：`ninfer-serve.exe <art> --host 127.0.0.1 --port <port> --spec mtp --draft-tokens 2 …`，完整参数见 docs/01 §5。
  - 端到端正确性看 `ninfer-perplexity.exe` 测出的 PPL：正确约 6.4–6.8，数值管线出错时会到几百。
  - `tools/verify/loadtest.cmd` 和 `gentest.cmd` 是可复现的装载/生成探针。
- **nvcc 测试台**编译的是引擎里同一份内核：
  - 先把 `rot_test.cu` 和 `gemm_test.cu` 里的输出目录常量（`<BUILD_ROOT>/bm2out/`）改成 ASCII 路径，再
    `nvcc -O2 -std=c++20 -arch=sm_89 -Xcompiler /wd4819 -I <engine>/src -o rot_test.exe tools/verify/harness/rot_test.cu`。
  - 旋转：运行 `rot_test.exe`，再用 `oracle_rot.py <dump-dir>` 比对。
  - GEMM：`gemm_oracle.py dump …` → `gemm_test.exe` → `gemm_oracle.py check …`。

引擎补丁里的运行期开关（环境变量）：

| 变量 | 作用 |
|---|---|
| `NINFER_TERNARY_MMA=0` | 关掉 T=2..8 的 mma 张量核路径，退回 SIMT，用于 A/B 验证 |
| `NINFER_TERNARY_HADAMARD=0` | 跳过所有旋转，只用于诊断或测速，此时输出是错的 |
| `NINFER_TERNARY_GDN_PERM=1` | 对 gdn/output 施加 P 置换。默认关闭，因为打包器已把 GDN 张量统一成 grouped 顺序 |
| `NINFER_TERNARY_DUMP_EMBED=<ASCII 路径>` | 导出 embedding 激活，供 `check_embedding.py` 做引擎侧验证 |

## 架构要点

- **格式**：`PQ2_0_G128`（每 128 个权重 34 B：fp16 scale + 32 B 的 2-bit 码）和 `PTQ1_0_G128`（每 128 个 28 B）。
  两者都存成 `row-split-k128-v1` 三平面（码 / 高位 / scale）。打包器**逐字节搬运码字**，绝不反量化再量化。
- **模板是骨架**：`pack.py` 遍历模板制品自己的对象表逐个映射，所以模板的 `identity.weights_id` 必须是 `groupwise-int`，
  `nvfp4` 版的融合命名会被拒。映射表以外的对象（`vision/*`、`mtp/*`、`frontend/*`、`text/draft_head*`、`dflash2/*`）
  原样从模板借用。**MTP 头就是这样借来的**：Bonsai 的 GGUF 没有 NextN 张量，而投机解码的速度全靠它。
- **旋转基**：激活侧做正向变换 `y = W'·(H·(s ⊙ (P·x)))`。H 是按 1024 分块的归一化 Walsh–Hadamard 矩阵；
  s 来自打包时附加的对象 `text/hadamard_signs` 和 `text/hadamard_widths`。只有 token_embd 查表之后做逆变换。
- **激活布局是 `ne[0]` 连续（token 主序）**：`x[k,t]` 位于 `t*K + k`。T=1 时它与行主序重合，所以只测 T=1 发现不了布局错误。
- **引擎侧代码**：
  - `src/ops/linear/ternary/` 放旋转、T=1 的 warp-per-row GEMV、T≥2 的 mma 路径（8-token tile，同时服务投机验证和 prefill）以及派发逻辑。
  - 各 fused 包装（attn/gdn 输入投影、swiglu、linear_add、embedding）都有三元分支，需要旋转工作区。
  - 折叠权重必须调用带 workspace 的 `linear(x, w, out, policy, workspace, stream)` 重载，LM head 也一样。
- 引擎树自带上游的 `AGENTS.md`，讲所有权边界、数值 op 要用独立 oracle 验收。其中 "Local operations" 一节写的是
  上游维护者的 Linux 机器，这里不适用。

## 验证与构建的硬规则（docs/04 的浓缩）

- **字节往返（"搬运无损"）对偏移错误和行置换完全盲**：
  - 查偏移看分布指纹：scale 全为正、高位字节种类少、`zero_share` = 0.3278。
  - 查置换要比较多重集，并按规则**直接逐行比对**，不要用"搜索第一个匹配"。
- GEMM、布局、变换类改动必须有 **T>1** 用例，并在**引擎侧**验证（注入式 dump）。独立 harness 只能证明公式自洽。
- 端到端正确性用 PPL 判断。性能数字以引擎自报为准；nsys 要加 `--cuda-graph-trace=node`；声称"提速"之前先用 rel_l2 核对结果。
- **改了任何 `.h`，都要 touch 所有 include 它的 `.cpp`**。本树的 MSVC 头文件依赖扫描是坏的，不这样做的话，
  改动会静默不生效，或者运行期出现 `/GS` 崩溃 `0xC0000409`。
- 不要用 `Get-Content`/`Set-Content` 整体重写源码：它会切掉尾行、加上 BOM，导致 `cudafe++ died 0xC0000409`。只做定点编辑。
- 链接前先停掉正在运行的 exe，否则报 `LNK1104`。同一个 build 目录同时只跑一个 ninja。
  原生 exe 的工作目录和 dump 路径一律用 ASCII。

## 发布约束

- 权重、`.ninfer` 制品和 `models/` 下的任何文件都不进仓库。
- 仓库内的文件不写机器相关路径，改用占位符（`<NINFER_ROOT>`、`<BUILD_ROOT>`、`<WORKSPACE>`、`<PYTHON>`、`<CUDA13>`、`<MODELS>`）。
  发布前按 `NOTICE.md` 末尾的脱敏清单逐项核对。
- `README.md` 顶部的 YAML 是魔搭（ModelScope）模型卡元数据，`license` 字段必须在平台白名单内。
- README 和 docs 里的数字都来自引擎自报的 timings 与 PPL 实测。改了相关代码要重测，不能凭推断改数字。
