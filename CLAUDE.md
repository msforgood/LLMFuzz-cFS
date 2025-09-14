# 수정 필요
Task ID Not Active 분기문에서 저 내용이 활성화되지 않도록 input 조정 - ds, time, sb, evs에서 발생 중
fm 에서는 1980-012-14:03:20.50234 FM App: Error registering for Event Services, RC = 0xC2000003
1980-012-14:03:20.50235 FM App: Error registering for Event Services, RC = 0xC2000003
1980-012-14:03:20.50236 FM App: Error registering for Event Services, RC = 0xC2000003
1980-012-14:03:20.50236 FM App: Error registering for Event Services, RC = 0xC2000003

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# ROLE

당신은 cFS 각 앱의 특정 함수에 대해 실제로 동작하는 퍼징 하니스를 작성하는 전문가다.

# RULE

퍼징 하니스의 타겟은 매 요청마다 (1)앱/(2)함수로 주어진다.

절대 파일을 삭제하지 않는다.
DO NOT DELETE any file.

# GOAL

타겟 앱의 타겟 함수에 대해, 검증 규칙을 통과하며 호출되는 퍼징 하니스를 완성한다.

# 핵심 단계(반드시 수행)

## 1) 타겟 앱 확인

```bash
cd ~/LLMFuzz-cFS/cFS/apps/{앱}/fuzz
git fetch origin
git checkout {앱}
git pull --rebase origin {앱}
```

## 2) 타겟 함수 확인

* 함수명과 function code(FC)를 파악한다.
* FC 매핑 근거를 `spec.json`에 기록한다.

## 3) 구조체 확인

* 헤더에서 타겟 함수가 소비하는 명령/데이터 구조체의 필드, 타입, 정렬, 패딩 규칙을 수집한다.

## 4) validate 확인

* 함수 흐름 상 통과해야 하는 모든 검증 조건을 정리한다.
* 예: 주소 범위/정렬, 길이 한계, 파일명/경로 규칙, 권한 플래그, 시퀀스 체크 등.

## 5) spec 문서화

* `~/LLMFuzz-cFS/cFS/apps/{앱}/fuzz/src/spec/{함수}_spec.json` 작성.
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

### `~/LLMFuzz-cFS/cFS/apps/{앱}/fuzz/src/{앱}_construct_packet.c`

하니스 규칙
* `LLVMFuzzerTestOneInput(uint8_t* data, size_t size)` 구현.
* 입력 바이트를 `spec.json`의 `struct_spec`에 맞춰 패킷을 구성.
* `validation_spec`을 반영해 조기 return 조건(경계 부족, 정렬 불일치 등) 추가.
* FC를 포함한 호출 코드로 실제 타겟 함수를 단일 호출 또는 소량 시나리오로 exercise.
* 추가 지시: 단순히 spec.json 구조체 필드를 매핑하는 것에 그치지 말고, context 기반 코드 커버리지의 depth를 최대화할 수 있도록 함수 문맥을 고려해 분기를 여는 입력을 직접 생성·주입하라. 다양한 입력 조건·시나리오(권한 비트, 정수 범위, 체크섬 일치/불일치, 리소스 존재/부재, 경계값, 정렬 위반, 문자열 경계, 시퀀스·상태 전이 등)를 구현하고 입력에서 결정되게 하라.

선언 위치
* 생성기 선언은 ~/LLMFuzz-cFS/cFS/apps/{앱}/fuzz/src/{앱}_construct_packet.h에만 작성.
* {앱}_fuzz.c에는 하니스 관련 함수 선언 금지.

초기화 의존
* ~/LLMFuzz-cFS/cFS/apps/ds/fuzz/dummy_bsp.c
* ~/LLMFuzz-cFS/cFS/apps/ds/fuzz/dummy_psp_module_list.c
* LLVMFuzzerTestOneInput 내 init 블록 삭제 금지.

멀티 생성기·앱별 엔트리 파이프
* 입력 첫 바이트를 결정적 셀렉터로 사용해 여러 생성기 중 하나를 선택.
* rand 사용 금지(재현성).
* 엔트리 파이프는 앱마다 다르므로 매크로 한 줄로 바꿔 끼운다.

멀티 함수 셀렉터(랜덤 디스패치) — 예시: ds_fuzz.c
* 입력의 첫 바이트(Data[0])를 결정적 셀렉터로 사용해 여러 *_ConstructPacket 중 하나를 선택한다.
* 나머지 바이트(Data+1 ..)는 선택된 생성기의 페이로드로 전달한다.
* 재현성을 위해 rand() 대신 입력 바이트만 사용한다(크래시 재현 용이).
* 생성기 개수가 1보다 작으면 즉시 return 0.

### `~/LLMFuzz-cFS/cFS/apps/{앱}/fuzz/CMakeLists.txt`

* fuzz 타깃 추가, 필요한 Sanitizer/LibFuzzer 플래그를 조건부 설정.

* 두 의존 파일(dummy_bsp.c, dummy_psp_module_list.c)과 생성기/엔트리 파일을 타깃에 포함.

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


## 8) Git 커밋, 푸시

* 작업 디렉터리: 리포지토리 루트 또는 `~/LLMFuzz-cFS/cFS/apps/{앱}/fuzz` 어디에서 실행해도 동작하도록 작성.
* 기준 브랜치: `{앱}`.
* 커밋 메시지 규칙: `feat(fuzz-{앱}): {함수} construct_packet & spec (FC={fc})`

### 변수 예시

* `{앱}`: 예) `mm`
* `{함수}`: 예) `MM_DumpMemToFileCmd`
* `{fc}`: 예) `6`

---

### 1) 변경 파일만 스테이징

```bash
SPEC=~/LLMFuzz-cFS/cFS/apps/{앱}/fuzz/src/spec/{함수}_spec.json
HARNESS=~/LLMFuzz-cFS/cFS/apps/{앱}/fuzz/src/{앱}_construct_packet.c
CMAKE=~/LLMFuzz-cFS/cFS/apps/{앱}/fuzz/CMakeLists.txt

git add "$SPEC" "$HARNESS" "$CMAKE"
```

### 2) 커밋 (메시지 템플릿)

```bash
MSG="feat(fuzz-{앱}): {함수} construct_packet & spec (FC={fc})"
git commit -m "$MSG" \
  -m "- spec: $SPEC" \
  -m "- construct: $HARNESS" \
  -m "- cmake: $CMAKE"
```

### 3) 푸시 (항상 새 브랜치)

```bash
git push origin {app}
```

---

### 꼭 기억할 것

* 하니스는 퍼징으로 **실행 가능해야 함**
* 스펙(JSON)과 코드가 **불일치하면 안 됨** (필드/타입/경계)
* PR의 **base 브랜치는 {앱}**
* 추가 빌드 플래그/의존이 생기면 `CMakeLists.txt` 또는 커밋 본문에 간단히 남겨 두기

# DO NOT

* 파일 삭제 금지.
* 허용 파일 외 수정/리팩터 금지.
* `spec.json`과 불일치하는 필드/타입/경계 사용 금지.

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
cd ~/LLMFuzz-cFS/cFS/apps/{app}/fuzz
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


---


Authored-By: Minseo Kim <mskim.link@gmail.com>