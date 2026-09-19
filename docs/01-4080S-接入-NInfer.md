# 01 · 把 NInfer 接入 RTX 4080 SUPER（Ada / sm_89 / Windows）

> 目标：在一张**消费级 Ada 卡 + Windows** 上，从源码把 NInfer 编出来、跑起来，
> 并能用命令行 / HTTP 服务两种方式与模型对话。
>
> 适用：RTX 4080 / 4080 SUPER / 4090（sm_89）；Windows + MSVC。Linux/Blackwell 走官方主线即可。

---

## 0. 为什么需要这份文档

NInfer 官方**只支持 Linux + RTX 5090（sm_120a）**，其 CMake **显式拒绝**其它架构：

> The build rejects CUDA architectures other than `sm_120a`.

在 Ada 上要跑，就得用**支持 Ada 的源码线**（早期 Windows 线）自行构建。本文记录的就是这条线在本机的完整落地过程与全部坑。

---

## 1. 环境清单（全部实测版本）

| 项 | 值 |
|---|---|
| GPU | NVIDIA GeForce RTX 4080 SUPER（AD103，**sm_89**，32,760 MiB）｜驱动 616.56 |
| 操作系统 | Windows 11 |
| CUDA | **13.3.33**（**旁装**，不覆盖系统 CUDA；回退 = 删目录） |
| 编译器 | MSVC **14.51.36231**（VS 18 BuildTools） |
| CMake | **4.4.3** |
| Ninja | **1.13.2** |
| Python（构建脚本/工具） | 3.12（需 `torch`、`numpy` 的解释器用于转换工具） |
| 物理内存 | 建议 ≥ 64 GB（转换大模型时占内存） |

> `nvcc` 单独编译时需显式 `-std=c++20`（本树用了 `namespace A::B` 语法）。

---

## 2. 获取源码

两条线：

- **上游主线**（Linux / 5090 / `sm_120a`）：`github.com/Neroued/ninfer`
- **Ada / Windows 线**（本项目所用）：早期 Windows 版本 + 本项目的三元改动（见 `patches/`）

目录约定（下文用变量表示，按你的实际盘符替换）：

```
<NINFER_ROOT>   源码树根（如 <盘>:\src\ninfer-<your-fork>）
<BUILD_ROOT>    构建目录（如 <盘>:\build\b1）—— 与源码树分离
<MODELS>        放 .ninfer 制品（如 <盘>:\models）
```

> ⚠️ **一条线一个构建目录。** 两个 `ninja` 打同一个 build dir 会**损坏**构建树。

---

## 3. 配置（CMake）

本机实测可用的配置命令（PowerShell / cmd 均可，先 `vcvars64.bat`）：

```bat
call "<VS>\VC\Auxiliary\Build\vcvars64.bat"
set CUDA_PATH=<CUDA>
set VSLANG=1033

cmake -S <NINFER_ROOT> -B <BUILD_ROOT> -G Ninja ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_CUDA_ARCHITECTURES=89 ^
  -DCMAKE_CUDA_COMPILER=<CUDA>/bin/nvcc.exe ^
  -DNINFER_BUILD_APPS=ON ^
  -DNINFER_BUILD_BENCHMARKS=OFF ^
  -DNINFER_DISABLE_MEDIA=ON
```

关键开关说明：

| 开关 | 值 | 原因 |
|---|---|---|
| `CMAKE_CUDA_ARCHITECTURES` | `89` | Ada（4080S/4090）|
| `NINFER_DISABLE_MEDIA` | `ON` | 该树不带 ffmpeg 依赖 ⇒ **不支持图片/视觉**（会报 `Compiled without FFMPEG support.`）。要视觉只能用官方 1.2.0 生产引擎 |
| `NINFER_BUILD_APPS` | `ON` | 产出 `ninfer.exe` / `ninfer-serve.exe` / `ninfer-perplexity.exe` |
| `VSLANG=1033` | — | 否则 MSVC 输出**中文**，破坏 ninja 的 `/showIncludes` 依赖扫描（见 §6.1）|

---

## 4. 构建

```bat
ninja -C <BUILD_ROOT> -j 8 -k 0
```

判据：出现 **`BUILD OK`**（0 错误）。产物在 `<BUILD_ROOT>\apps\`。

### ⛔ 4.1 本树最危险的坑：**MSVC 头文件依赖扫描是坏的**

- **症状**：改了 `.h`，`ninja` 说"没活干"（或只重编极少数 TU）。日志里是中文 `注意: 包含文件:`，ninja 的 `/showIncludes` 解析不了。
- **后果**：改动**静默不生效**；跨 TU 结构体尺寸不一致 ⇒ 运行期 **`/GS` 栈金丝雀崩溃 `0xC0000409`**；或链接期报**旧签名的未解析符号**。
- **对策**：**改任何 `.h` 之后，必须 `touch` 所有 include 它的 `.cpp`**：

```powershell
foreach ($f in @('<NINFER_ROOT>\src\ops\linear\linear.cpp',
                 '<NINFER_ROOT>\src\targets\qwen3_6_27b\impl\variant.cpp',
                 '<NINFER_ROOT>\src\targets\qwen3_6\impl\runtime\text_context_impl.h')) {
  (Get-Item $f).LastWriteTime = Get-Date
}
```

> 长效办法：写一个 `build-loop.cmd`，循环跑 `ninja` 直到 `rc==0` 或进度停滞（本项目脚本的 40 轮重试 + 停滞检测）。

---

## 5. 运行

### 5.1 命令行一次问答

```
<BUILD_ROOT>\apps\ninfer.exe <MODELS>\<model>.ninfer --prompt "你的问题" --max-new 200
```

### 5.2 OpenAI 兼容服务

```
<BUILD_ROOT>\apps\ninfer-serve.exe <MODELS>\<model>.ninfer ^
  --host 127.0.0.1 --port 8080 ^
  --max-context 131072 --kv-capacity 131072 ^
  --kv-dtype fp8 --max-concurrency 2 ^
  --spec mtp --draft-tokens 2
```

端点：`/v1/chat/completions`、`/v1/models`。

### 5.3 档位差异（**照抄别的档会炸**）

Ada 线的 KV dtype **不能用 `k8v4`**（需 sm_120）；只能 `bf16|int8|fp8`。
磁盘缓存、`rk8v4` 等都是**新线专有**，Ada 线没有（传了会 `unknown argument` 直接退出）。

---

## 6. 坑清单（**每条都有症状原文**）

| # | 症状 | 真因 / 对策 |
|---|---|---|
| 6.1 | 改 `.h` 不触发重编；运行期 `/GS` 崩溃 `0xC0000409` | 依赖扫描坏（§4.1）。改 `.h` 后 touch 所有 `.cpp` |
| 6.2 | `nvcc error : 'cudafe++' died with status 0xC0000409` | **源文件结构被破坏**（花括号不平衡）。别清 `tmpxft_*`、别挪 pdb——**先 diff 括号**。成因多是用 `Get-Content`/`Set-Content` 整体重写源码 |
| 6.3 | `cudaErrorStreamCaptureUnsupported`（进程被 fastfail） | CUDA 图捕获期**禁止 `cudaStreamSynchronize`**。调试 dump 先查 `cudaStreamIsCapturing` |
| 6.4 | `LNK1104 无法打开文件 apps\ninfer*.exe` | 有进程在跑该 exe ⇒ 先停进程再链 |
| 6.5 | 第三方库的**组件子目录**进了 include，报 `C2039/C2873 "localtime": 不是 global namespace 的成员` | 如 `-I …/include/libavutil` **遮蔽了系统 `<time.h>`**。只放**包根** `include/` |
| 6.6 | 源码含非 ASCII 字面量时报与编码无关的语法错 | MSVC 按代码页 936 解码会**吞引号**。加 `/utf-8`（C/CXX）与 `-Xcompiler=/utf-8`（CUDA）。⚠️ `/Zc:preprocessor-` 对此**无效** |
| 6.7 | `nvtx3/…/nvtxInit.h` 报 `_wgetenv` 相关 `C3861` | CUDA 13.3 该头缺 `<stdlib.h>`。在自家 `src/core/nvtx.h` 里补 `#include <stdlib.h>`（放 nvtx 头之前）|
| 6.8 | 原生 exe / nsys 在中文工作目录下崩（`working_directory contains invalid UTF-8`）| **工具一律用 ASCII 工作目录** |
| 6.9 | 中文 prompt 走 `--prompt` 报 `failed to normalize UTF-8 text as NFC` | 中文必须走 `--messages <json>`（UTF-8 无 BOM）|
| 6.10 | 健康检查卡住 | 别用 `Invoke-WebRequest`；用 `curl.exe` |

---

## 7. 判据：怎么算"接入成功"

1. `ninfer.exe` 能装载 `.ninfer` 并打印 `engine ready`；
2. `--prompt "The capital of France is"` 输出**通顺**（不通顺 = 数值管线有系统性错误）；
3. `ninfer-serve.exe` 起来后 `curl /v1/models` 能列出模型（id = artifact 身份，如 `qwen3.8-27b`）。

---

## 8. 收工纪律

- `Stop-Process` 停引擎 → `nvidia-smi` 确认显存回落 → 不与其它 GPU 任务抢卡；
- 换模型必须**验证显存回落到基线**才算上一轮退干净。
