# LLMFuzz-cFS

LLMFuzz-cFS is a research prototype that explores the use of Large Language Models (LLMs) to automatically generate fuzzing harnesses for [NASA's cFS (core Flight System)](https://github.com/nasa/cFS) applications. This project aims to support domain-specific memory vulnerability discovery through LLM-assisted static and dynamic analysis of command structures.

---

## ✨ Features

- Automatically extracts packet structures based on function codes
- Identifies validation logic to determine input constraints
- Generates initial fuzzing harness code compatible with `libFuzzer`
- Supports target applications such as **MM (Memory Manager)** in cFS
- Integrates with Clang-based build environments

---

## 📁 Project Structure

```
LLMFuzz-cFS/
├── prompts/             # Prompt templates for LLM inference
├── outputs/             # LLM-generated harness code
├── src/
│   ├── parser/          # Static analyzer for cFS source code
│   └── harness/         # Fuzzing harness generator logic
├── testcases/           # Known CVE/PoC samples for evaluation
└── README.md
```

---

## 🔧 Setup

This project assumes the presence of a local cFS repository and a Clang/LLVM-based environment.

```bash
git clone https://github.com/your-org/LLMFuzz-cFS.git
cd LLMFuzz-cFS
# (Optional) Set up Python environment
pip install -r requirements.txt
```

---

## 🧠 How It Works

1. **Input**: Source code of cFS app (e.g., MM)
2. **LLM Analysis**: Extract command packet structure & validation logic
3. **Harness Generation**: Generate fuzzing-compatible C/C++ harness
4. **Execution**: Build and run with libFuzzer

---

## 🧪 Target Example: MM App

Function Code | Command | Struct | Status
--------------|---------|--------|--------
`0x06`        | DumpMemToFile | `MM_DumpMemToFileCmd_t` | Harness generated

---

## 🗓️ Roadmap

- [x] Proof-of-concept for MM App
- [ ] Expand support to other cFS apps (FM, TBL, etc.)
- [ ] Integrate LLM-in-the-loop refinement
- [ ] Publish benchmark results on CVE reproductions

---

## 📜 License

For research use only. This project is part of a security research initiative and is not affiliated with or endorsed by NASA.

---

## 👤 Contact

If you are interested in collaboration or further research:

- Name: [Kim Minseo]
- Email: [mskim.link@gmail.com]
- Institution: [Kyung Hee Univ., PWNLAB]
