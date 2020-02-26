call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat"
call scons -c platform=windows bits=64 target=debug
call scons platform=windows bits=64 target=debug
copy libqodot\build\libqodot.dll addons\qodot\bin\win64\
copy libqodot\build\libqodot.pdb addons\qodot\bin\win64\
copy libqodot\libmap\build\libmap.dll addons\qodot\bin\win64\
copy libqodot\libmap\build\libmap.pdb addons\qodot\bin\win64\