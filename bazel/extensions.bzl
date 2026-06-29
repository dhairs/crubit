# Part of the Crubit project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

load("@rules_rust//rust:repositories.bzl", "rust_repository_set")
load("@rules_rust//rust/platform:triple.bzl", "get_host_triple")
load("@toolchains_llvm//toolchain:rules.bzl", "llvm_toolchain")
load("//bazel:versions.bzl", "LLVM_MAP")

def _crubit_toolchains_impl(ctx):
    # Default toolchain configurations
    rust_version = "nightly/2026-05-31"
    llvm_version = None
    llvm_extra_distributions = {}
    dev_components = True
    
    user_llvm_repo = None
    user_rust_repo = None

    # Detect the host triple as a reasonable default for exec_triple.
    exec_triple = get_host_triple(ctx).str

    # Read tags from the root module (or downstream modules)
    for mod in ctx.modules:
        for config in mod.tags.configure:
            if config.rust_version:
                rust_version = config.rust_version
            if config.llvm_version:
                llvm_version = config.llvm_version
            if config.llvm_extra_distributions:
                llvm_extra_distributions = config.llvm_extra_distributions
            if config.exec_triple:
                exec_triple = config.exec_triple
            if config.dev_components != None:
                dev_components = config.dev_components
            if config.llvm_toolchain:
                user_llvm_repo = config.llvm_toolchain
            if config.rust_toolchain:
                user_rust_repo = config.rust_toolchain

    # 1. Define the LLVM repository.
    # It must be named "llvm_toolchain" to satisfy Crubit's default internal label references.
    if user_llvm_repo:
        pass
    else:
        mapped_config = LLVM_MAP.get(rust_version, {})
        final_llvm_version = llvm_version or mapped_config.get("version", "21.1.8")
        final_sha256 = mapped_config.get("sha256")
        final_urls = mapped_config.get("urls")
        final_strip_prefix = mapped_config.get("strip_prefix")

        if final_urls:
            llvm_toolchain(
                name = "llvm_toolchain",
                llvm_version = final_llvm_version,
                urls = {"": final_urls},
                sha256 = {"": final_sha256},
                strip_prefix = {"": final_strip_prefix},
            )
        else:
            llvm_toolchain(
                name = "llvm_toolchain",
                llvm_version = final_llvm_version,
                extra_llvm_distributions = llvm_extra_distributions,
            )

    # 2. Define the Rust repository.
    if not user_rust_repo:
        rust_repository_set(
            name = "rust_toolchain",
            edition = "2024",
            versions = [rust_version],
            exec_triple = exec_triple,
            dev_components = dev_components,
            register_toolchain = False,
        )

crubit_toolchains = module_extension(
    implementation = _crubit_toolchains_impl,
    tag_classes = {
        "configure": tag_class(
            attrs = {
                "rust_version": attr.string(doc = "The version of Rust to install."),
                "llvm_version": attr.string(doc = "The version of LLVM to install."),
                "llvm_extra_distributions": attr.string_dict(doc = "Custom SHA256 mapping for LLVM tarballs."),
                "exec_triple": attr.string(doc = "The Rust-style target triple that the compiler runs on."),
                "dev_components": attr.bool(doc = "Whether to download the rustc-dev components.", default = True),
                "llvm_toolchain": attr.label(doc = "External LLVM repository to use."),
                "rust_toolchain": attr.label(doc = "External Rust toolchain hub to use."),
            }
        )
    }
)
