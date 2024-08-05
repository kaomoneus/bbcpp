# Better C++ Bazel
Only thing you need is to put .cpp files in proper place. Those rules will grab them automatically.

# NOTE
Current `foo` sample created for builds on RPi and Darwin. For demonstration it depends on prebuilt external jsoncpp static lib.
If you want to test sample on any other platforms, use `foo-universal` which doesn't have such deps.
