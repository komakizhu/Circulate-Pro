cmake_minimum_required(VERSION 3.14.0)

option(SMTG_ENABLE_VST3_PLUGIN_EXAMPLES "Enable VST 3 Plug-in Examples" OFF)
option(SMTG_ENABLE_VST3_HOSTING_EXAMPLES "Enable VST 3 Hosting Examples" OFF)
option(CIRCULATE_ENABLE_AUV2 "Build the macOS Audio Unit v2 wrapper" OFF)

set(CMAKE_OSX_DEPLOYMENT_TARGET 10.13 CACHE STRING "")

set(vst3sdk_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/vst3sdk" CACHE PATH
    "Path to the Steinberg VST3 SDK")
if(NOT EXISTS "${vst3sdk_SOURCE_DIR}/CMakeLists.txt")
    message(FATAL_ERROR "Path to VST3 SDK is empty!")
endif()

project(Circulate
    # This is your plug-in version number. Change it here only.
    # Version number symbols usable in C++ can be found in
    # source/version.h and ${PROJECT_BINARY_DIR}/projectversion.h.
    VERSION 2.0.0.0 
    DESCRIPTION "Circulate VST 3 Plug-in"
)

if(CIRCULATE_ENABLE_AUV2)
    set(CIRCULATE_AUDIOUNIT_SDK_PATH "${CMAKE_CURRENT_SOURCE_DIR}/third_party/AudioUnitSDK" CACHE PATH
        "Path to Apple's AudioUnitSDK")
    if(NOT EXISTS "${CIRCULATE_AUDIOUNIT_SDK_PATH}/include/AudioUnitSDK/AUBase.h")
        message(FATAL_ERROR "AudioUnitSDK 1.1+ is required to build the AUv2 wrapper")
    endif()
    set(SMTG_AUDIOUNIT_SDK_PATH "${CIRCULATE_AUDIOUNIT_SDK_PATH}" CACHE PATH
        "Path to Apple's AudioUnitSDK" FORCE)
    set(SMTG_ENABLE_AUV2_BUILDS ON CACHE BOOL "Enable AUv2 builds" FORCE)
endif()

set(SMTG_VSTGUI_ROOT "${vst3sdk_SOURCE_DIR}")

# CMake 4.4 can leave the Objective-C++ compile rule unset when using the
# Unix Makefiles generator on macOS. VSTGUI needs Objective-C++ sources, so
# provide the standard rule explicitly for that generator. The Xcode
# generator does not need this fallback.
if(APPLE AND CMAKE_GENERATOR MATCHES "Makefiles" AND NOT CMAKE_OBJCXX_COMPILE_OBJECT)
    set(CMAKE_INCLUDE_FLAG_OBJCXX "-I")
    execute_process(
        COMMAND xcrun --sdk macosx --show-sdk-path
        OUTPUT_VARIABLE CIRCULATE_MACOS_SDK_PATH
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    if(CIRCULATE_MACOS_SDK_PATH)
        string(APPEND CMAKE_OBJCXX_FLAGS
            " -stdlib=libc++ -isysroot ${CIRCULATE_MACOS_SDK_PATH}"
            " -mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
    endif()
    set(CMAKE_OBJCXX_COMPILE_OBJECT
        "<CMAKE_OBJCXX_COMPILER> <DEFINES> <INCLUDES> -x objective-c++ <FLAGS> -o <OBJECT> -c <SOURCE>")
endif()

add_subdirectory(${vst3sdk_SOURCE_DIR} ${PROJECT_BINARY_DIR}/vst3sdk)
smtg_enable_vst3_sdk()

smtg_add_vst3plugin(Circulate
    source/version.h
    source/cids.h
    source/processor.h
    source/processor.cpp
    source/controller.h
    source/controller.cpp
    source/entry.cpp
    build/DenormalProtection.h
)

target_include_directories(Circulate
    PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/build"
)

#- VSTGUI Wanted ----
if(SMTG_ENABLE_VSTGUI_SUPPORT)
    target_sources(Circulate
        PRIVATE
            resource/editor.uidesc
    )
    target_link_libraries(Circulate
        PRIVATE
            vstgui_support
    )
    smtg_target_add_plugin_resources(Circulate
        RESOURCES
            "resource/editor.uidesc"
    )
endif(SMTG_ENABLE_VSTGUI_SUPPORT)
# -------------------

smtg_target_add_plugin_snapshots (Circulate
    RESOURCES
        resource/8324F606598653AA96620D195BF7DA24_snapshot.png
        resource/8324F606598653AA96620D195BF7DA24_snapshot_2.0x.png
)

target_link_libraries(Circulate
    PRIVATE
        sdk
)

smtg_target_configure_version_file(Circulate)

if(SMTG_MAC)
    smtg_target_set_bundle(Circulate
        BUNDLE_IDENTIFIER com.circulate.gulldsp
        COMPANY_NAME "GullDSP"
    )
    smtg_target_set_debug_executable(Circulate
        "/Applications/VST3PluginTestHost.app"
        "--pluginfolder;$(BUILT_PRODUCTS_DIR)"
    )

    if(CIRCULATE_ENABLE_AUV2 AND XCODE)
        list(PREPEND CMAKE_MODULE_PATH
            "${CMAKE_CURRENT_SOURCE_DIR}/cmake"
            "${vst3sdk_SOURCE_DIR}/cmake/modules"
        )
        include(SMTG_AddVST3AuV2)
        smtg_target_add_auv2(Circulate-au
            BUNDLE_NAME Circulate
            BUNDLE_IDENTIFIER com.gulldsp.circulate.auv2
            INFO_PLIST_TEMPLATE "${CMAKE_CURRENT_SOURCE_DIR}/resource/au-info.plist"
            VST3_PLUGIN_TARGET Circulate
        )
        set_target_properties(Circulate-au PROPERTIES
            XCODE_ATTRIBUTE_MACOSX_DEPLOYMENT_TARGET "11.0"
        )
        if(CIRCULATE_AUV2_STAGING_DIR)
            add_custom_command(TARGET Circulate-au POST_BUILD
                COMMAND "${CMAKE_COMMAND}" -E make_directory "${CIRCULATE_AUV2_STAGING_DIR}"
                COMMAND "${CMAKE_COMMAND}" -E copy_directory
                    "${CMAKE_BINARY_DIR}/VST3/$<CONFIG>/Circulate.component"
                    "${CIRCULATE_AUV2_STAGING_DIR}/Circulate.component"
            )
        endif()
    elseif(CIRCULATE_ENABLE_AUV2)
        message(FATAL_ERROR "AUv2 requires the Xcode generator on macOS")
    endif()
elseif(SMTG_WIN)
    target_sources(Circulate PRIVATE 
        resource/win32resource.rc
    )
    if(MSVC)
        set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT Circulate)

        smtg_target_set_debug_executable(Circulate
            "$(ProgramW6432)/Steinberg/VST3PluginTestHost/VST3PluginTestHost.exe"
            "--pluginfolder \"$(OutDir)/\""
        )
    endif()
endif(SMTG_MAC)
