#!/bin/bash

# 인자 확인
if [ -z "$1" ]; then
  echo "사용법: $0 <앱이름>"
  exit 1
fi

APP=$1

# 해당 앱의 fuzz 디렉토리로 이동
cd cFS/apps/$APP/fuzz || { echo "apps/$APP/fuzz 경로가 존재하지 않습니다."; exit 1; }

# build 디렉토리 생성 및 이동
mkdir -p build
cd build || exit 1

# CMake 실행
cmake .. || { echo "cmake 실패"; exit 1; }

# 빌드 실행
make -j$(nproc) || { echo "make 실패"; exit 1; }

# fuzz 실행
./${APP}_fuzz
