:: Copyright 2025 The Amber Authors.
::
:: Licensed under the Apache License, Version 2.0 (the "License");
:: you may not use this file except in compliance with the License.
:: You may obtain a copy of the License at
::
::     http://www.apache.org/licenses/LICENSE-2.0
::
:: Unless required by applicable law or agreed to in writing, software
:: distributed under the License is distributed on an "AS IS" BASIS,
:: WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
:: See the License for the specific language governing permissions and
:: limitations under the License.

@echo on

set BUILD_ROOT=%cd%
set SRC=%cd%\github\amber
set BUILD_TYPE=%1
set VS_VERSION=%2

:: Force usage of python 3.12
set PATH=C:\python312;%PATH%
:: Force usage of cmake 3.31.2
set PATH=C:\cmake-3.31.2\bin;%PATH%

cd %SRC%
python tools\git-sync-deps

:: #########################################
:: set up msvc build env
:: #########################################
if %VS_VERSION% == 2019 (
  call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
) else if %VS_VERSION% == 2022 (
  call "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat" x64
)

cmake --version

cd %SRC%
mkdir build
cd build

:: #########################################
:: Start building.
:: #########################################
echo "Starting build... %DATE% %TIME%"
if "%KOKORO_GITHUB_COMMIT%." == "." (
  set BUILD_SHA=%KOKORO_GITHUB_PULL_REQUEST_COMMIT%
) else (
  set BUILD_SHA=%KOKORO_GITHUB_COMMIT%
)

cmake -GNinja -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DCMAKE_C_COMPILER=cl.exe -DCMAKE_CXX_COMPILER=cl.exe -DAMBER_USE_LOCAL_VULKAN=1 ..
if %ERRORLEVEL% GEQ 1 exit /b %ERRORLEVEL%

echo "Build everything... %DATE% %TIME%"
ninja
if %ERRORLEVEL% GEQ 1 exit /b %ERRORLEVEL%
echo "Build Completed %DATE% %TIME%"

:: ################################################
:: Run the tests (We no longer run tests on VS2013)
:: ################################################
echo "Running Tests... %DATE% %TIME%"
amber_unittests
if %ERRORLEVEL% GEQ 1 exit /b %ERRORLEVEL%
echo "Tests Completed %DATE% %TIME%"

exit /b %ERRORLEVEL%
