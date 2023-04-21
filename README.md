<div align="center">

# CMakeTemplate

[![Repo Size](https://img.shields.io/github/repo-size/TheMagehawk/CMakeTemplate)](https://github.com/TheMagehawk/CMakeTemplate)
[![License](https://img.shields.io/github/license/TheMagehawk/CMakeTemplate)](https://github.com/TheMagehawk/CMakeTemplate/blob/master/LICENSE)

A flexible, extensible and cross-platform <b>CMake Template</b> to compile small and large C and C++ Projects

</div>

## :information_source: Usage
### :bricks: Setup

Create a new repository from the Template on Github:  
`git clone https://github.com/TheMagehawk/CMakeTemplate.git`

### :gear: Configuration

Now you can write custom source files in the `src` directory.
Source files need to be added in the CMakeLists.txt:

`list(APPEND SOURCE_FILES ...)`

External dependencies can be added as Git submodules or Local Copies into the `external` directory.
The target name for each dependency needs to be addressed in the CMakeLists.txt:

`list(APPEND LIBS ...)`

Additional flags or variables can be set directly in the Root CMakeLists.txt!

### :arrows_counterclockwise: Continuous integration

This Template is provided with Github Workflow Jobs to automate compilation.<br>
To enable the jobs remove `if: False` or replace it with `if: True` for each desired job.

## :hammer_and_wrench: Build
### :vs: Visual Studio

- Initialize and update all submodules in this project (including external modules/dependencies):  
 `git submodule update --init --recursive --depth=1`
- Configure the CMake Project (and delete and regenerate Cache if needed or error)
- Run one of the available Configurations

### :printer: Command Line

#### :penguin: Linux:
- Run `chmod +x build.sh && ./build.sh [FLAGS]`

#### :window: Windows:
- Run `./build.bat [FLAGS]`

#### :apple: MacOS:
- Run `chmod +x build.sh && ./build.sh [FLAGS]`

#### :robot: Android (Experimental right now):
- Cross Compile on **Windows:**<br/>
`./build.bat --android [NDK_PATH]`
- Cross Compile on **Linux:**<br/>
`./build.sh --android [NDK_PATH]`

#### :green_apple: iOS:
- Maybe someday...

### :triangular_flag_on_post: Configuration/Build Flags
`./build.sh --help` or `./build.bat --help` as flags to print out all available build flags
