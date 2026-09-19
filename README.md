---
license: Apache License 2.0
tasks:
- text-generation
frameworks:
- pytorch
libraries:
- ninfer
- gguf
language:
- zh
- en
tags:
- ninfer
- ternary
- 1.58-bit
- bonsai
- ada
- sm-89
- rtx-4080-super
- windows
- quantization
- hadamard
base_model: Qwen/Qwen3.8-27B
new_version: ''
datasets: []
metrics: []
---

# NInfer on Ada · 三元 Bonsai 2 27B 实战移植（RTX 4080 SUPER / Windows）

> 把 **NInfer** 推理引擎接到 **消费级 Ada 卡（RTX 4080 SUPER, sm_89, Windows）**，
> 并把 **Ternary Bonsai 2 27B**（1.58-bit 三元 + Hadamard 旋转基）移植进 NInfer 原生 `.ninfer`。
> 本仓是**技术成品展示 + 可复现文档 + 工具链**，不是一份权重分发。

---

## TL;DR

| 项 | 结果 |
|---|---|
| **端到端正确性** | ✅ 输出通顺；**PPL 6.445**（黄金参照 6.8196 ± 0.5365，同量级且略优） |
| **单流速度（MTP K=2）** | ✅ **96.7 – 130.8 t/s**（4/5 真实负载 ≥ 101 t/s） |
| 纯解码（T=1） | 62 – 64 t/s |
| 预填充（prefill） | 356 – 439 tok/s |
| 制品尺寸 | **7.74 GB**（文本部分 6.696 GiB，落在 5.5–7.2 GiB 红线内） |
| 20 题社区基准（MMLU/MMLU-Pro/ZebraLogic/AIME/HumanEval） | **16/20 = 80%**（同引擎全精度 27B 为 18/20） |

**它做了什么**：给 NInfer 加了一种它原本没有的权重格式（三元 + 运行时 Hadamard 旋转），
并让整条链在本机 32 GB 的 Ada 卡上跑通、达标。**全社区此前没有第二家**把三元接进 NInfer。

---

## 本仓包含什么

```
README.md                      ← 本文（模型卡片）
NOTICE.md                      ← 第三方来源与许可声明
LICENSE                        ← Apache License 2.0
docs/
  01-4080S-接入-NInfer.md       ← 让 NInfer 在 Ada/Windows 上跑起来
  02-微调模型转-NInfer.md       ← 把普通（微调）模型转成 .ninfer
  03-三元模型转-NInfer.md       ← 把三元模型移植进 NInfer（本项目主线）
  04-工程实录-坑与方法学.md      ← 踩过的坑与验证方法学（最值钱的部分）
tools/
  pack.py                      ← GGUF → .ninfer 三元打包器
  MAPPING.json                 ← 逐张量映射规格（权威）
  verify/                      ← 4 个装配/解包验证脚本 + 旋转/GEMM oracle
patches/
  changed-files/               ← 引擎侧源码改动（与上游 fork 同结构，覆盖即可）
  README-改动说明.md            ← 改动清单 + 重建 + 必须做的验证
```

---

## 三份技术文档（核心交付）

### ① [4080S 接入 NInfer](docs/01-4080S-接入-NInfer.md)
消费级 Ada（sm_89）+ Windows 上把 NInfer 编出来、跑起来：环境、构建、运行、档位、坑。

### ② [微调模型 → .ninfer](docs/02-微调模型转-NInfer.md)
把任意**受支持架构**的 HF safetensors 微调模型转成 NInfer 原生 `.ninfer`（用引擎自带的
`tools/convert/` 配方框架）。**零引擎改动**。

### ③ [三元模型 → .ninfer](docs/03-三元模型转-NInfer.md)
把**三元 + Hadamard 旋转基**的模型移植进 NInfer：新增格式、旋转内核、fused 家族接线、
GEMV/mma 两条快路径、打包器。**本项目的主体工作**。

---

## 数据从哪来（诚实交代）

- 速度/正确性数字全部来自**引擎自报 timings + PPL 实测**，不是估算；
- 每一步判据都写在对应文档里（"正确应看到什么、错误会看到什么"）；
- 关键结论都带**负控**与**独立旁证**（详见 ④）。

---

## 许可与来源

本项目为 **NInfer（Apache-2.0）** 的派生作品，并消费 **PrismML 的 Ternary Bonsai 2 27B** 权重。
详见 [NOTICE.md](NOTICE.md)。

- 引擎与工具：Apache License 2.0
- 权重（不在本仓分发）：来自 PrismML / Qwen 体系，遵循其各自许可
