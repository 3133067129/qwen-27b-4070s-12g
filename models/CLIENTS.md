# 把本地三元 Bonsai 2 27B 接到各种工具

启动：`D:\projects\qwen3.8_fast\models\start_bonsai_agent.cmd`（启动并等到就绪，约 85-110 s）
配置：`D:\projects\qwen3.8_fast\models\.env`

## 已验证的兼容性（本机实测）

| 能力 | 结果 |
|---|---|
| `GET /v1/models` | ✅ 返回 `qwen3.8-27b` |
| `POST /v1/chat/completions`（非流式） | ✅ |
| `POST /v1/chat/completions`（**stream SSE**） | ✅ 分块正常 |
| **function / tool calling** | ✅ `tool_calls` 正常返回 |
| `POST /v1/messages`（**Anthropic 协议**） | ✅ 返回 Anthropic 形状响应 |
| 带 `Authorization: Bearer <任意>` | ✅ 不校验（本地服务） |
| 真实 OpenAI Python SDK（chat / stream / tools） | ✅ 三项全通 |
| **模型名必须精确匹配** | ⚠️ 只服务一个 id，其他名字 → **404** |

## 各工具怎么配

### Cline / Roo Code（VS Code）
Provider 选 **OpenAI Compatible**：
- Base URL: `http://127.0.0.1:8099/v1`
- API Key: `sk-local`（随便填）
- Model ID: `qwen3.8-27b`

Cline 的系统提示很长，8192 上下文会比较紧。建议先把引擎开大一点再启动：
`set CTX=16384` + `set KV=fp8`（显存占用与 8192+bf16 相同）。

### Continue（VS Code / JetBrains）
`~/.continue/config.yaml`：
```yaml
models:
  - name: Bonsai 27B ternary (local)
    provider: openai
    model: qwen3.8-27b
    apiBase: http://127.0.0.1:8099/v1
    apiKey: sk-local
    contextLength: 8192
    roles: [chat, edit, apply]
```

### Aider
```bash
set -a; . D:/projects/qwen3.8_fast/models/.env; set +a
aider --model openai/qwen3.8-27b --no-stream
```
Aider 需要较长上下文；若报超长，改用 `--map-tokens 1024` 之类把仓库地图压小。

### Open WebUI / LiteLLM 代理
```
OPENAI_API_BASE_URL=http://127.0.0.1:8099/v1
OPENAI_API_KEY=sk-local
```
LiteLLM 里模型写 `openai/qwen3.8-27b`。

### Claude Code / 其他 Anthropic 客户端
```bash
set -a; . D:/projects/qwen3.8_fast/models/.env; set +a   # ANTHROPIC_BASE_URL / ANTHROPIC_AUTH_TOKEN
```

### LangChain / LlamaIndex
```python
from langchain_openai import ChatOpenAI
llm = ChatOpenAI(base_url="http://127.0.0.1:8099/v1", api_key="sk-local",
                 model="qwen3.8-27b", temperature=0)
```

### 裸 OpenAI SDK / curl
```python
from openai import OpenAI
client = OpenAI(base_url="http://127.0.0.1:8099/v1", api_key="sk-local")
client.chat.completions.create(model="qwen3.8-27b",
    messages=[{"role": "user", "content": "hi"}], max_tokens=64)
```
```bash
curl http://127.0.0.1:8099/v1/chat/completions -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-local" \
  -d "{\"model\":\"qwen3.8-27b\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}],\"max_tokens\":32}"
```

## 工具写死了模型名怎么办
有些工具只给 `gpt-4o` 之类的下拉框。服务端只服务一个模型 id，但可以**改名字**：
```bat
rem start_bonsai_agent.cmd 顶部
set MODEL_ID=gpt-4o
```
然后把 `.env` 里的 `OPENAI_MODEL` / `ANTHROPIC_MODEL` 一起改成 `gpt-4o`（实测：改名后 `gpt-4o` 可用了，而原来的 `qwen3.8-27b` 变成 404）。

## 注意事项
- **一次一个模型**：这张 12 GB 卡跑这套配置后只剩 ~1 GiB 余量，先 `ollama ps` 确认没有别的模型驻留。
- **首字延迟**：服务没预热时第一句要等 ~85 s；用 `start_bonsai_agent.cmd` 就不会踩到。
- **并发**：`--max-concurrency 1`，不要同时跑多个 agent。
- **思考模式**：服务脚本里带了 `--no-thinking`（token 省 6-7 倍、20 题实测更准）。要思维链就删掉该开关并把 `MAX_TOKENS` 调大。
- 结束：`Get-Process ninfer-serve | Stop-Process -Force`


## Claude Code（VS Code 插件）—— 已配置好

CC Switch 里新增了一个 provider：**「Bonsai 27B 本地 (NInfer)」**（已设为当前）。
`~/.claude/settings.json` 也已按该 provider 写好，所以插件直接可用。

### 用之前先起引擎
```bat
D:\projects\qwen3.8_fast\models\start_claude_bonsai.cmd     :: 启动并等到就绪（~86s）
D:\projects\qwen3.8_fast\models\stop_claude_bonsai.cmd      :: 用完释放显存
```

### 三个必须的开关（少一个就连不上）
| 配置 | 取值 | 为什么 |
|---|---|---|
| `behavesAs` | `claude-haiku-4-5` | Claude Code 2.1.x 拒绝模型目录里没有的 id；`modelPicker` 行 + `behavesAs` 才能让它接受 `qwen3.8-27b`。选 haiku 而不是 sonnet-5，是因为 sonnet-5 的档位会带 `output_config.effort`，引擎会报 `reasoning effort conflicts with enable_thinking` |
| `MAX_THINKING_TOKENS=0` | 必填 | 否则 Claude Code 会发 `thinking.display='omitted'`，引擎不支持加密隐藏推理，直接 400 |
| `CLAUDE_CODE_MAX_CONTEXT_TOKENS=65536` | 必填 | 不声明的话 CLI 按 200k 估算，auto-compact 永远不触发，最后被引擎拒掉 |

### 引擎侧为什么用 MTP 而不是 DFlash2
| 配置 | 最大上下文（实测） | 能否跑 Claude Code |
|---|---|---|
| DFlash2 K=4 | **~16k**（24576 差 9 MB 装不下） | ❌ Claude Code 基础 prompt（system + 22 个工具）就超了，报 `prepared prompt exceeds Engine max_context 16384` |
| MTP K=3 | **64k**（131072 装不下） | ✅ 实测通过 |

同一份三元权重、同样 `--no-thinking`，只是把投机后端从 DFlash2 换成 MTP（解码 64.8 vs 82.5 tok/s）；agent 循环是 prefill 主导，实际差别远小于这个数字。


## 上下文天花板（12 GB 卡实测）

| 配置 | 规划阶段 | 实际可用？ | 实测 prefill |
|---|---|---|---|
| MTP K=3 · 65536 · fp8 KV | 通过 | ✅ | **456 tok/s**（冷启），缓存命中后 260 tok/s |
| MTP K=3 · 81920 · fp8 KV | 通过 | ❌ 显存打满（11.7/12.3 GB）→ 驱动分页 | **186 tok/s**，长请求 10 分钟不返回 |
| 无投机 · 98304 · fp8 KV | 通过 | ❌ 显存打满（11.8/12.3 GB） | **14 tok/s** |

**结论：规划阶段报 "fits" 不等于能跑**——它只保证分配得下，不保证有工作余量。这张卡上 65536 是真正的天花板，往上只会慢到不可用。

## 撞到 max_context 时怎么办

引擎硬上限 65536，但 Claude Code 的"声明窗口"设成了 **49152**（`CLAUDE_CODE_MAX_CONTEXT_TOKENS`），
目的是让 auto-compact 在 ~43-45k 就触发，给单次大工具输出（读大文件、grep 结果）留 ~20k 余量。
之前声明窗口 = 引擎上限（65536），压缩阈值贴着硬墙，一次 10k 的跳变就直接 400。

手工兜底：`/compact` 手动压缩，或直接开新会话。真需要更大窗口只能换卡（或换更小的模型）。
