scons -c platform=osx target=debug fat_binary=yes
scons platform=osx target=debug fat_binary=yes
cp libqodot/build/libqodot.so addons/qodot/bin/osx/
cp libqodot/libmap/build/libmap.so addons/qodot/bin/osx/
