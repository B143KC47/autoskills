# Folder / Codebase Scan → Skill Domains (input mode 2)

When pointed at a repo/folder, infer what skills would help: detect signals, then map signals → domains → queries.

## How to scan
1. Glob top-level + key files. For breadth, dispatch the `Explore` agent.
2. Read manifests/configs and the README.
3. Collect signals from the table; produce one query per detected domain.

## Signal → domain table
| Signal (files / contents) | Inferred domain | Example queries |
|---|---|---|
| `requirements.txt`, `pyproject.toml`, `*.py` | Python project | (refine by libs below) |
| `package.json`, `*.ts/tsx`, `next.config.*` | Web / JS/TS | react, nextjs, frontend-design |
| `torch`, `transformers`, `*.ipynb`, training loop | ML training | fine-tuning, deepspeed, flash-attention, peft |
| `trl`, `peft`, `lora`, RLHF configs | Fine-tuning / RL | trl-fine-tuning, unsloth, grpo-rl-training |
| `lm-eval`, benchmark/eval scripts | Model evaluation | lm-evaluation-harness, nemo-evaluator |
| `Dockerfile`, k8s manifests, CI yaml | DevOps / deploy | docker, deploy, ci-cd |
| `vllm`, `sglang`, serving config | Inference serving | vllm, sglang, tensorrt-llm |
| vector DB clients (`chroma`, `faiss`, `qdrant`, `pinecone`) | Retrieval / RAG | chroma, faiss, langchain, llamaindex |
| many untested modules / low coverage | Testing | tdd, testing, playwright |
| `*.tsx`/`*.vue`/`*.svelte` + styling | UI/UX | ui-ux-pro-max, frontend-design |

## Output
A proposed *toolkit*: for each detected domain run Steps 2–5 of the main workflow and present the top skill per domain, grouped by domain. Record the toolkit under a `skillmap-<stack>.md` category if useful.
