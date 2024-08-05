load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _get_basename(path):
    return path.split('/')[::-1][0]

def _get_default_name():
    return _get_basename(native.package_name())

def _get_test_name(name):
    return name + "_test"

def _get_test_lib_name(name):
    return name + "_test_lib"

def _add_test_rule(orig_name, srcs, glob_tests, test_defines, args):
    args.pop("defines", None)
    if test_defines:
        args["defines"] = test_defines

    deps = args.get("deps", [])
    deps.append(":" + orig_name)
    deps.append("//test_hive_queen:test_hive_queen")
    args["deps"] = deps

    srcs = _pop_and_glob("srcs", args, ["test/**/*.cpp"]) if glob_tests else srcs

    if srcs:
        args["srcs"] = srcs

    native.cc_library(
        name = _get_test_lib_name(orig_name),
        # Not sure we've to bother about visibility for tests
        # visibility = visibility,
        **args
    )

    native.cc_binary(
        name = _get_test_name(orig_name),
        # Not sure we've to bother about visibility for tests
        # visibility = visibility,
        **args
    )

def _link_static():
    return select({
        "//:config_arm-linux-gnueabihf": ["-static"],
        "//conditions:default": [],
    })



def we_import(
    name=None,
    static=True, dynamic=False,
    visibility=None,
):
    if not name:
        name = _get_default_name()

    if not visibility:
        visibility = ["//visibility:public"]
    
    import_name = "%s_import" % name
    import_as_dep = ":" + import_name
    cc_import_args = dict(
        name = import_name,
        hdrs = native.glob(["include/**/*.h"]),
    )
    if static:
        libname = ("lib%s.a" % name)
        static_lib = select({
            "//:config_arm-linux-gnueabihf": "lib/arm-linux-gnueabihf/" + libname,
            "//:config_x86_64-darwin": "lib/x86_64-darwin/" + libname,
            "//conditions:default": "unknown",
        })
        cc_import_args["static_library"] = static_lib
        
    # if dynamic:
    #    cc_import_args["static_library"] = lib_prefix + ("lib%s.a" % name)
    
    native.cc_import(**cc_import_args)
    native.cc_library(
        name = name,
        hdrs = native.glob(["include/**/*.h"]),
        includes = ["include"],
        deps = [import_as_dep],
        visibility = visibility,
        strip_include_prefix = "include",
    )

def _pop_and_glob(attr_name, args, glob_value):
    res = args.pop(attr_name, default=[]) + native.glob(glob_value)
    return res

def we_lib(
    name=None,
    visibility=None,
    glob_srcs=True,
    glob_hdrs=True,
    glob_tests=True,
    test_defines=None,
    test_srcs=None,
    **args,
):
    if not name:
        name = _get_default_name()

    if not visibility:
        visibility = ["//visibility:public"]

    srcs = _pop_and_glob("srcs", args, ["impl/**/*.cpp", "impl/**/*.cc"]) if glob_srcs else args.pop("srcs", None)
    hdrs = _pop_and_glob("hdrs", args, ["include/**/*.h", "include/**/*.inc"]) if glob_hdrs else args.pop("hdrs", None)

    cc_lib_args = dict(
        name=name,
        strip_include_prefix = "include",
        visibility = visibility,
        **args
    )

    if srcs:
        cc_lib_args["srcs"] = srcs

    if hdrs:
        cc_lib_args["hdrs"] = hdrs

    native.cc_library(**cc_lib_args)

    if glob_tests or test_srcs:
        _add_test_rule(name, test_defines=test_defines, srcs=test_srcs, glob_tests=glob_tests, args=args)

def we_bin(
    name=None,
    **args,
):
    if not name:
        name = _get_default_name()

    lib_name = name + "_lib"

    linkstatic = args.pop("linkstatic", None)

    if linkstatic == None:
        linkstatic = [] + _link_static()

    cc_args=dict(
        name=name,
        deps=[":%s" % lib_name]
    )

    if linkstatic:
        cc_args["linkopts"] = args.pop("linkopts", []) + linkstatic
        cc_args["linkstatic"] = True

    # FIXME: we had to separate lib and bin
    #    because we need strip_include_prefix to be applied, which
    #    is not defined for cc_binary rule.
    we_lib(lib_name, **args)
    native.cc_binary(**cc_args)


def _local_archive_impl(repository_ctx):
      repository_ctx.extract(repository_ctx.attr.src)
      repository_ctx.file(
          "BUILD.bazel",
          repository_ctx.read(repository_ctx.attr.build_file)
      )

we_local_archive = repository_rule(
    attrs = {
        "src": attr.string(mandatory = True),
        "build_file": attr.label(mandatory = True, allow_single_file = True),
    },
    implementation = _local_archive_impl,
)

def we_archive(
    name, url,
    build_file,
    **kwargs,
):
    file_prefix = "file://"
    if url.startswith(file_prefix):
        we_local_archive(
            name=name,
            src=url[len(file_prefix):],
            build_file=build_file
        )
    else:
        http_archive(
            name=name,
            url=url,
            **kwargs,
        )
