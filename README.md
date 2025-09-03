# cFS Fuzzer with LLM

A comprehensive fuzzing infrastructure for NASA's Core Flight System (cFS) enhanced with Large Language Model (LLM) capabilities for intelligent test case generation and security vulnerability discovery.

## Overview

This project combines NASA's Core Flight System with automated fuzzing techniques and LLM-powered analysis to systematically test cFS applications for security vulnerabilities, memory safety issues, and robustness failures.

### Key Features

- **Automated Fuzzer Generation**: LLM-powered harness creation for cFS applications
- **Comprehensive Coverage**: Supports all major cFS apps (CF, CS, DS, FM, MM, etc.)
- **Intelligent Test Cases**: LLM-guided packet construction based on function specifications
- **Security Focus**: Targets memory safety, input validation, and protocol compliance
- **Reproducible Testing**: Deterministic fuzzing for reliable vulnerability reproduction

## Architecture

```
claude-mcp/
├── cFS/                    # NASA Core Flight System bundle
│   ├── apps/               # Flight applications with fuzzing infrastructure
│   │   ├── cf/fuzz/        # CFDP file transfer fuzzing
│   │   ├── cs/fuzz/        # Checksum service fuzzing
│   │   ├── ds/fuzz/        # Data storage fuzzing
│   │   ├── fm/fuzz/        # File manager fuzzing
│   │   └── mm/fuzz/        # Memory manager fuzzing
│   ├── cfe/                # Core Flight Executive
│   ├── osal/               # OS Abstraction Layer
│   └── psp/                # Platform Support Package
└── CLAUDE.md              # LLM instructions for fuzzer development
```

## Fuzzing Infrastructure

Each cFS application contains a dedicated `fuzz/` directory with:

### Core Components
- **`{app}_construct_packet.c`**: LibFuzzer entry points with intelligent packet construction
- **`spec/{function}_spec.json`**: Function specifications and validation rules
- **`cfe_init_fuzzer.c`**: cFE initialization stubs for isolated testing
- **`CMakeLists.txt`**: Build configuration with sanitizer support

### Specification Format
```json
{
  "target": { "function": "MM_DumpMemToFileCmd", "fc": 6 },
  "struct_spec": {
    "header": { "ccsds": "standard 12-byte header" },
    "payload": { "fields": [{"name": "SymAddress", "type": "CFS_SymAddr_t"}] }
  },
  "validation_spec": {
    "ranges": { "addr": ["0x08000000", "0x08100000"] },
    "align": 4,
    "filename": "^[A-Za-z0-9._-]+$"
  },
  "fc_mapping": { "table": "MM_CMD_MID + FC offset" }
}
```

## Getting Started

### Prerequisites

- **Clang 14**: Required for LibFuzzer support
- **CMake 3.10+**: Build system
- **Linux**: Primary development platform
- **Git**: Version control with submodules

### Quick Setup

```bash
# Clone with submodules
git clone --recursive https://github.com/your-repo/claude-mcp.git
cd claude-mcp/cFS

# Initialize cFS build system
git submodule update --init
cp cfe/cmake/Makefile.sample Makefile
cp -r cfe/cmake/sample_defs sample_defs

# Build cFS framework
make distclean
make SIMULATION=native prep
make && make install
```

### Building Fuzzers

```bash
# Build fuzzer for specific app (e.g., Memory Manager)
cd cFS/apps/mm/fuzz
mkdir build && cd build
cmake ..
make -j$(nproc)

# Run fuzzer
./mm_fuzz
```

## LLM-Powered Development

This project uses Claude Code with specialized instructions in `CLAUDE.md` for:

### Automated Harness Generation
- Function analysis from cFS source code
- Command structure reverse engineering  
- Validation rule extraction
- Test case prioritization

### Intelligent Fuzzing Strategies
- Protocol-aware packet construction
- Constraint-based input generation
- Coverage-guided mutation
- Vulnerability pattern recognition

## Development Workflow

### 1. Target Selection
```bash
cd ~/claude-mcp/cFS/apps/{app}/fuzz
git fetch origin && git checkout {app}
git pull --rebase origin {app}
```

### 2. Function Analysis
- Identify target function and command code (FC)
- Extract data structures from headers
- Document validation requirements

### 3. Specification Creation
- Write `spec/{function}_spec.json`
- Define packet structure and constraints
- Map function codes to commands

### 4. Harness Implementation
- Implement packet construction logic
- Add validation bypasses
- Integrate with LibFuzzer

### 5. Testing & Validation
```bash
mkdir build && cd build
cmake .. && make -j$(nproc)
./{app}_fuzz  # Verify fuzzer operation
```

## Security Testing Focus

### Memory Safety
- Buffer overflow detection
- Use-after-free vulnerabilities
- Double-free conditions
- Memory leak identification

### Input Validation
- Command parameter fuzzing
- File path traversal attempts
- Integer overflow/underflow
- Format string vulnerabilities

### Protocol Compliance
- CCSDS header validation
- Command sequence testing
- State machine verification
- Timing attack resistance

## Coverage & Results

### Sanitizer Integration
- **AddressSanitizer**: Memory error detection
- **UndefinedBehaviorSanitizer**: Undefined behavior detection
- **LeakSanitizer**: Memory leak detection

### Reporting
- Crash reproduction cases
- Coverage metrics
- Performance profiling
- Vulnerability classifications

## Contributing

### Fuzzer Development Rules
1. **File Restrictions**: Only modify permitted fuzzing files
2. **Branch Management**: Work on app-specific branches
3. **Specification Compliance**: Maintain spec/code consistency
4. **Commit Format**: Use standardized commit messages

### Commit Template
```
feat(fuzz-{app}): {function} construct_packet & spec (FC={fc})

- spec: ~/claude-mcp/cFS/apps/{app}/fuzz/src/spec/{function}_spec.json
- construct: ~/claude-mcp/cFS/apps/{app}/fuzz/src/{app}_construct_packet.c
- cmake: ~/claude-mcp/cFS/apps/{app}/fuzz/CMakeLists.txt
```

## cFS Framework Information

This project is built on NASA's Core Flight System:

- **Version**: Based on cFS Aquila release (cFE 6.7.0, OSAL 5.0.0)
- **License**: Apache 2.0
- **Documentation**: See [cFS official documentation](https://cfs.gsfc.nasa.gov)
- **Applications**: CF, CS, DS, FM, MM, plus lab applications

## License

This fuzzing infrastructure follows the same Apache 2.0 license as the underlying cFS framework. See the cFS repository for complete license information.

## Contact & Support

For questions about the fuzzing infrastructure:
- Create GitHub issues for bug reports
- Use discussions for questions and ideas

For cFS framework support:
- Email: cfs-program@lists.nasa.gov
- Website: https://cfs.gsfc.nasa.gov
- Community: cfs-community@lists.nasa.gov

---

**Security Notice**: This tool is designed for defensive security testing only. Use responsibly on authorized systems.