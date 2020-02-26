scons -c platform=x11 bits=64 target=debug
scons platform=x11 bits=64 target=debug
cp libqodot/build/libqodot.so addons/qodot/bin/x11/
cp libqodot/libmap/build/libmap.so addons/qodot/bin/x11/
