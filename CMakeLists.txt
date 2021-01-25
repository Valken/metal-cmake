cmake_minimum_required(VERSION 3.0)
project(HeavyMetal)
set(CMAKE_CXX_STANDARD 20)

add_executable(HeavyMetal MACOSX_BUNDLE
  metal.m
  library.metal
  external/imgui_demo.cpp
  external/imgui_draw.cpp
  external/imgui_tables.cpp
  external/imgui_widgets.cpp
  external/imgui.cpp
  external/backends/imgui_impl_metal.mm
  external/backends/imgui_impl_osx.mm)

set_source_files_properties(library.metal PROPERTIES LANGUAGE METAL)

set_property(TARGET HeavyMetal APPEND_STRING PROPERTY COMPILE_FLAGS "-fobjc-arc -x objective-c++")
set_target_properties(HeavyMetal PROPERTIES MACOSX_BUNDLE_BUNDLE_NAME "Heavy Metal")
target_include_directories(HeavyMetal PRIVATE ./external ./external/backends)
target_link_libraries(HeavyMetal "-framework AppKit" "-framework QuartzCore" "-framework Metal")