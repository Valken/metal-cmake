cmake_minimum_required(VERSION 3.0)
project(HeadyMetal)

add_executable(HeavyMetal MACOSX_BUNDLE
  metal.m
  library.metal)

set_source_files_properties(library.metal PROPERTIES LANGUAGE METAL)

set_property(TARGET HeavyMetal APPEND_STRING PROPERTY COMPILE_FLAGS "-fobjc-arc")
set_target_properties(HeavyMetal PROPERTIES MACOSX_BUNDLE_BUNDLE_NAME "Heavy Metal")
target_link_libraries(HeavyMetal "-framework AppKit" "-framework QuartzCore" "-framework Metal")