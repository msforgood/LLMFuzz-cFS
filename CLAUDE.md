# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# ROLE

당신은 cFS 각 앱의 특정 함수에 대해 실제로 동작하는 퍼징 하니스를 작성하는 전문가다.

# RULE

퍼징 하니스의 타겟은 매 요청마다 (1)앱/(2)함수로 주어진다.

변경 가능한 파일은 다음으로 제한한다.

* `~/claude-mcp/cFS/apps/{앱}/fuzz/src/spec/{함수}_spec.json`
* `~/claude-mcp/cFS/apps/{앱}/fuzz/src/{앱}_construct_packet.c`
* `~/claude-mcp/cFS/apps/{앱}/fuzz/src/{앱}_fuzz.c`
* `~/claude-mcp/cFS/apps/{앱}/fuzz/CMakeLists.txt`

# GOAL

타겟 앱의 타겟 함수에 대해, 검증 규칙을 통과하며 호출되는 퍼징 하니스를 완성한다.

# 핵심 단계(반드시 수행)

## 1) 타겟 앱 확인

```bash
cd ~/claude-mcp/cFS/apps/{앱}/fuzz
git fetch origin
git checkout {앱}
git pull --rebase origin {앱}
```

* `{앱}` 브랜치가 없다면 `origin/{앱}`에서 새로 만들고 최신화한다.

## 2) 타겟 함수 확인

* 함수명과 function code(FC)를 파악한다.
* FC 매핑 근거를 `spec.json`에 기록한다.

## 3) 구조체 확인

* 헤더에서 타겟 함수가 소비하는 명령/데이터 구조체의 필드, 타입, 정렬, 패딩 규칙을 수집한다.

## 4) validate 확인

* 함수 흐름 상 통과해야 하는 모든 검증 조건을 정리한다.
* 예: 주소 범위/정렬, 길이 한계, 파일명/경로 규칙, 권한 플래그, 시퀀스 체크 등.

## 5) spec 문서화

* `~/claude-mcp/cFS/apps/{앱}/fuzz/src/spec/{함수}_spec.json` 작성.
* 예시:

```json
{
  "target": { "function": "{함수명}", "fc": 6 },
  "struct_spec": { "header": { "ccsds": "..." }, "payload": { "fields": [/*...*/] } },
  "validation_spec": { "ranges": { "addr": ["0x...","0x..."] }, "align": 4, "filename": "^[A-Za-z0-9._-]+$" },
  "fc_mapping": { "table": "/* 근거 주석 또는 헤더 상수 이름 */" },
  "constraints": { "max_len": 4096, "min_len": 16, "endianness": "LE" },
  "notes": { "preconditions": ["cFE init stubbed"], "side_effects": ["no file write on dry-run"] }
}
```

## 6) 하니스 구현

### `~/claude-mcp/cFS/apps/{앱}/fuzz/src/{앱}_construct_packet.c`

* `LLVMFuzzerTestOneInput(uint8_t* data, size_t size)` 구현.
* 입력 바이트를 `spec.json`의 `struct_spec`에 맞춰 패킷을 구성.
* `validation_spec`을 반영해 조기 return 조건(경계 부족, 정렬 불일치 등) 추가.
* FC를 포함한 호출 코드로 실제 타겟 함수를 단일 호출 또는 소량 시나리오로 exercise.

멀티 함수 셀렉터(랜덤 디스패치) — 예시: ds_fuzz.c

* 입력의 첫 바이트(Data[0])를 결정적 셀렉터로 사용해 여러 *_ConstructPacket 중 하나를 선택한다.
* 나머지 바이트(Data+1 ..)는 선택된 생성기의 페이로드로 전달한다.
* 재현성을 위해 rand() 대신 입력 바이트만 사용한다(크래시 재현 용이).
* 생성기 개수가 1보다 작으면 즉시 return 0.

### `~/claude-mcp/cFS/apps/{앱}/fuzz/CMakeLists.txt`

* fuzz 타깃 추가, 필요한 Sanitizer/LibFuzzer 플래그를 조건부 설정.


## 7) 동작 테스트

```bash
cd apps/{앱}/fuzz
mkdir build
cd build
cmake ..
make -j$(nproc)
./{앱}_fuzz
```

명령어를 통해 실제로 퍼저가 작동하는지 확인.
작동하지 않으면 이유를 찾고 작동하도록 수정.


## 8) Git 반영

* 작업 디렉터리: 리포지토리 루트 또는 `~/claude-mcp/cFS/apps/{앱}/fuzz` 어디에서 실행해도 동작하도록 작성.
* 기준 브랜치: `{앱}`.
* 변경 파일 보호: **허용된 3개 파일만** 스테이징/커밋.
* 새 브랜치로 푸시: **main에 직접 푸시 금지**.
* 커밋 메시지 규칙: `feat(fuzz-{앱}): {함수} construct_packet & spec (FC={fc})`

### 변수 예시

* `{앱}`: 예) `mm`
* `{함수}`: 예) `MM_DumpMemToFileCmd`
* `{fc}`: 예) `6`

---

### 1) 브랜치 최신화 (앱 브랜치 기준)

```bash
cd ~/claude-mcp/cFS/apps/{앱}/fuzz
git fetch origin
git checkout {앱}
git pull --rebase origin {앱}
```

* 앱 브랜치가 없다면 `git checkout -b {앱} origin/{앱}`(원격에 있으면) 또는 `main`에서 분기해도 됩니다.

### 2) 작업 브랜치 만들기

```bash
BRANCH="fuzz/{앱}/{함수}-fc{fc}-$(date -u +%Y%m%d-%H%M%S)"
git switch -c "$BRANCH"
```

* 규칙: `fuzz/{앱}/{함수}-fc{fc}-타임스탬프`

### 3) 변경 파일만 스테이징

```bash
SPEC=~/claude-mcp/cFS/apps/{앱}/fuzz/src/spec/{함수}_spec.json
HARNESS=~/claude-mcp/cFS/apps/{앱}/fuzz/src/{앱}_construct_packet.c
CMAKE=~/claude-mcp/cFS/apps/{앱}/fuzz/CMakeLists.txt

git add "$SPEC" "$HARNESS" "$CMAKE"
```

### 4) 커밋 (메시지 템플릿)

```bash
MSG="feat(fuzz-{앱}): {함수} construct_packet & spec (FC={fc})"
git commit -m "$MSG" \
  -m "- spec: $SPEC" \
  -m "- construct: $HARNESS" \
  -m "- cmake: $CMAKE"
```

### 5) 푸시 (항상 새 브랜치)

```bash
git push -u origin "$BRANCH"
```

* main에 직접 푸시 금지, force-push 금지

---

### 꼭 기억할 것

* 스펙(JSON)과 코드가 **불일치하면 안 됨** (필드/타입/경계)
* PR의 **base 브랜치는 {앱}**
* 추가 빌드 플래그/의존이 생기면 `CMakeLists.txt` 또는 커밋 본문에 간단히 남겨 두기

# DO NOT

* 허용 파일 외 수정/리팩터 금지.
* `spec.json`과 불일치하는 필드/타입/경계 사용 금지.
* main에 직접 푸시 금지, force-push 금지.

# Architecture Overview

This repository contains NASA's Core Flight System (cFS) with custom fuzzing infrastructure for security testing.

## Core Structure

- **cFS/**: Main cFS bundle with framework components
  - **cfe/**: Core Flight Executive - the framework kernel 
  - **osal/**: Operating System Abstraction Layer
  - **psp/**: Platform Support Package
  - **apps/**: Flight applications (cf, cs, ds, fm, mm, etc.)
  - **libs/**: Reusable libraries
  - **tools/**: Development and utility tools

## Fuzzing Infrastructure

Each app contains a `fuzz/` directory with:
- **src/**: Fuzzing harnesses and utilities
  - **spec/**: JSON specifications for target functions
  - **{app}_construct_packet.c**: LibFuzzer entry points
  - **cfe_init_fuzzer.c**: cFE initialization stubs
- **CMakeLists.txt**: Build configuration for fuzzing

## Build Commands

### cFS Framework
```bash
# Initial setup
git submodule update --init
cp cfe/cmake/Makefile.sample Makefile  
cp -r cfe/cmake/sample_defs sample_defs

# Build for native simulation
make distclean  # Clean previous builds
make SIMULATION=native prep  # Configure build
make  # Build all components
make install  # Install to build/exe/cpu1/

# Run with unit tests and coverage
make ENABLE_UNIT_TESTS=true prep
make test  # Run unit tests
make lcov  # Generate coverage reports
```

### Fuzzing Harnesses
```bash
# Build individual app fuzzer (requires Clang 14)
cd ~/claude-mcp/cFS/apps/{app}/fuzz
mkdir build && cd build
cmake ..
make -j$(nproc)
```

## Development Workflow

1. Work on app-specific branches (`git checkout {app}`)
2. Modify only the three permitted fuzzing files
3. Create feature branches with format `fuzz/{app}/{function}-fc{fc}-timestamp`
4. Always target app branch for PRs, never main

## Key Requirements

- **Clang 14** for fuzzing builds (compatibility with LibFuzzer)
- cFS initialization stubbing for isolated testing
- Strict file modification limits for fuzzing work
- Function code (FC) mapping from command specifications