add_library(PS2KeyAdvanced
    PS2KeyAdvanced.h
    PS2KeyAdvanced.cpp
)

target_link_libraries(PS2KeyAdvanced
    pico_stdlib
    hardware_gpio
)

target_include_directories(PS2KeyAdvanced PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")