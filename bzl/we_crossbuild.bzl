load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load("//:.user_config.bzl", "platforms")
load("//:.user_config.bzl", "toolchains")
load("@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "flag_group",
    "flag_set",
    "tool_path",
)

all_link_actions = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
]

all_compile_actions = [
    ACTION_NAMES.assemble,
    ACTION_NAMES.c_compile,
    ACTION_NAMES.clif_match,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.lto_backend,
    ACTION_NAMES.preprocess_assemble,
]

def _we_clangxx_impl(ctx):
    compiler_root = ctx.attr.toolchain_root
    compiler_version = ctx.attr.clang_version
    compiler_bin = "%s/bin" % compiler_root
    target_triple= ctx.attr.triple
    sysroot = ctx.attr.sysroot
    extra_defs = ctx.attr.compiler_defs
    extra_compiler_flags = ctx.attr.compiler_flags
    extra_linker_flags = ctx.attr.linker_flags

    # WARGNING WARNING WARNING:
    #    if you bump into R_ARM_ relocation errors,
    #    it probably means that compiler tries to link dynamic library,
    #    whilst it is a symlink associated with *absolute* path.
    #    if you cross-compile, then this path will be wrong.
    #    Easiest way to prove this is to try -static flag.
    #    Good way to fix that: go and fix that symlink.
    # extra_linker_flags = extra_linker_flags + ["-static"]
    # https://stackoverflow.com/questions/55942607/llvm-crosscompile-cant-create-dynamic-relocation-r-arm-abs32/75048788#75048788

    tools = {
        "ar":"llvm-ar",
        "cpp":"clang-cpp",
        "gcc": "clang++",
        "ld": "ld.lld",
        "nm": "llvm-nm",
        "objdump": "llvm-objdump",
        "strip": "llvm-strip",
        "gcov": "",
    }

    tool_paths = [
        tool_path(
            name = tool_name,
            path = "%s/%s" % (compiler_bin, tool_file) if tool_file else "false" ,
        )
        for tool_name, tool_file in tools.items()
    ]

    sysroot_arg = "--sysroot=%s" % sysroot
    target_arg = "--target=%s" % target_triple
    use_lld_arg = "-fuse-ld=lld"

    compiler_flags = [
        "-D%s" % compiler_def
        for compiler_def in extra_defs
    ] + extra_compiler_flags + [
        sysroot_arg, target_arg,
    ]

    linker_flags = extra_linker_flags + [sysroot_arg, target_arg, use_lld_arg]

    default_compiler_flags = feature(
        name = "default_compiler_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = compiler_flags,
                    ),
                ],
            ),
        ],
    )

    default_linker_flags = feature(
        name = "default_linker_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = ([
                    flag_group(
                        flags = linker_flags,
                    ),
                ]),
            ),
        ],
    )

    features = [
        default_compiler_flags,
        default_linker_flags,
    ]

    # Setting up sysroot and toolchain includes is stupid.
    # We only need it because bazel requires it to be defined
    # as dependencies.
    sysroot_includes = [
        "%s/usr/include" % sysroot,
        "%s/include" % sysroot,
    ]

    toolchain_includes = [
        "%s/lib/clang/%s/include" % (compiler_root, compiler_version)
    ]

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        cxx_builtin_include_directories = sysroot_includes + toolchain_includes,
        features = features,
        toolchain_identifier = ctx.attr.toolchain_identifier,
        host_system_name = "local",
        target_system_name = "unknown",
        target_cpu = "unknown",
        target_libc = "unknown",
        compiler = "clang",
        abi_version = "unknown",
        abi_libc_version = "unknown",
        tool_paths = tool_paths,
    )


we_clangxx_toolchain_config = rule(
    implementation = _we_clangxx_impl,
    attrs = {
        "toolchain_root": attr.string(doc="Local path to toolchain root"),
        "clang_version": attr.string(
            doc="Version os clang (required for proper system includes declaration"
        ),
        "sysroot": attr.string(doc="Local path to system root"),
        "triple": attr.string(
            doc="Toolchain triple like ('arm-linux-gnueabihf' and so on), passed as --target value"
        ),
        "compiler_defs": attr.string_list(doc="List of compiler definitions"),
        "compiler_flags": attr.string_list(doc="List of compiler flags"),
        "linker_flags": attr.string_list(doc="List of linker flags"),
        "toolchain_identifier": attr.string()
    },
    provides = [CcToolchainConfigInfo],
)

def we_clangxx_toolchain(
    name,
    toolchain_root,
    clang_version,
    sysroot,
    host_compatible_with,
    target_compatible_with,
    triple = None,
    compiler_defs = None,
    compiler_flags = None,
    linker_flags = None,
):

    config_name = "%s_config" % name
    cc_name = "cc_%s_toolchain" % name
    cc_identifier = "cc_%s_toolchain_id" % name

    we_clangxx_toolchain_config(
        name=config_name,
        toolchain_root=toolchain_root,
        clang_version=clang_version,
        sysroot=sysroot,
        triple=triple if triple else name,
        compiler_defs=compiler_defs if compiler_defs else [],
        compiler_flags=compiler_flags if compiler_flags else [],
        linker_flags=linker_flags if linker_flags else [],
        toolchain_identifier=cc_identifier,
    )

    native.filegroup(name = "empty")

    native.cc_toolchain(
        name = cc_name,
        toolchain_identifier = cc_identifier,
        toolchain_config = ":%s" % config_name,
        all_files = ":empty",
        compiler_files = ":empty",
        dwp_files = ":empty",
        linker_files = ":empty",
        objcopy_files = ":empty",
        strip_files = ":empty",
    )

    native.toolchain(
        name = name,
        exec_compatible_with = host_compatible_with,
        target_compatible_with = target_compatible_with,
        toolchain = cc_name,
        toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    )

# Called in workspace
def register_all_toolchains():
    [
        native.register_toolchains("//:%s" % toolchain_name)
        for toolchain_name in toolchains.keys()
    ]

# Called in BUILD
def declare_all_platforms():
    [
        native.platform(name=name, **kwargs)
        for name, kwargs in platforms.items()
    ]

# Called in BUILD
def declare_all_clangxx_toolchains():
    [
        we_clangxx_toolchain(name=name, **kwargs)
        for name, kwargs in toolchains.items()
    ]