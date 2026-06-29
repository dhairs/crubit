# Part of the Crubit project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

"""Mapping of Rust versions to LLVM versions and their SHA256 hashes."""

LLVM_MAP = {
    "nightly/2026-05-31": {
        "version": "22.1.0",
        "sha256": "663d9df63a71ba5cd2649e88af34c2c00aa4285e0c7e5e7b68da7b42c3799b90",
        "urls": [
            "https://github.com/llvm/llvm-project/releases/download/llvmorg-22.1.0-rc2/LLVM-22.1.0-rc2-Linux-X64.tar.xz",
        ],
        "strip_prefix": "LLVM-22.1.0-rc2-Linux-X64",
    },
}
