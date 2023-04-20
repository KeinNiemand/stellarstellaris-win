#Borrowed from https://gitlab.com/jhamberg/cmake-examples/-/blob/master/cmake/CheckGit.cmake

set(CURRENT_LIST_DIR ${CMAKE_CURRENT_LIST_DIR})
if (NOT DEFINED pre_configure_dir)
    set(pre_configure_dir ${CMAKE_CURRENT_LIST_DIR})
endif ()

if (NOT DEFINED post_configure_dir)
    set(post_configure_dir ${CMAKE_BINARY_DIR}/generated)
endif ()

set(pre_configure_file ${pre_configure_dir}/git_version.cpp.in)
set(post_configure_file ${post_configure_dir}/git_version.cpp)

function(CheckGitWrite GIT_HASH)
    file(WRITE ${CMAKE_BINARY_DIR}/git-state.txt ${GIT_HASH})
endfunction()

function(CheckGitRead GIT_HASH)
    if (EXISTS ${CMAKE_BINARY_DIR}/git-state.txt)
        file(STRINGS ${CMAKE_BINARY_DIR}/git-state.txt CONTENT)
        LIST(GET CONTENT 0 var)

        set(${GIT_HASH} ${var} PARENT_SCOPE)
    endif ()
endfunction()

function(CheckGitVersion)
    # Get the latest abbreviated commit hash of the working branch
    execute_process(
        COMMAND git rev-parse --short HEAD
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        OUTPUT_VARIABLE GIT_HASH
        OUTPUT_STRIP_TRAILING_WHITESPACE
        )



    CheckGitRead(GIT_HASH_CACHE)
    if (NOT EXISTS ${post_configure_dir})
        file(MAKE_DIRECTORY ${post_configure_dir})
    endif ()

    if (NOT EXISTS ${post_configure_dir}/git_version.h)
        file(COPY ${pre_configure_dir}/git_version.h DESTINATION ${post_configure_dir})
    endif()

    if (NOT DEFINED GIT_HASH_CACHE)
        set(GIT_HASH_CACHE "INVALID")
    endif ()

    # Only update the git_version.cpp if the hash has changed. This will
    # prevent us from rebuilding the project more than we need to.
    if (NOT EXISTS ${post_configure_file} OR NOT ${GIT_HASH} STREQUAL ${GIT_HASH_CACHE} )
        # Set che GIT_HASH_CACHE variable the next build won't have
        # to regenerate the source file.
        CheckGitWrite(${GIT_HASH})

        configure_file(${pre_configure_file} ${post_configure_file} @ONLY)
    endif ()

endfunction()

function(CheckGitSetup)

    add_custom_target(AlwaysCheckGit COMMAND ${CMAKE_COMMAND}
        -DRUN_CHECK_GIT_VERSION=1
        -Dpre_configure_dir=${pre_configure_dir}
        -Dpost_configure_file=${post_configure_dir}
        -DGIT_HASH_CACHE=${GIT_HASH_CACHE}
        -P ${CURRENT_LIST_DIR}/CheckGit.cmake
        BYPRODUCTS ${post_configure_file}
        )

    add_library(git_version ${CMAKE_BINARY_DIR}/generated/git_version.cpp)
    target_include_directories(git_version PUBLIC ${CMAKE_BINARY_DIR}/generated)
    add_dependencies(git_version AlwaysCheckGit)

    CheckGitVersion()
endfunction()

# This is used to run this function from an external cmake process.
if (RUN_CHECK_GIT_VERSION)
    CheckGitVersion()
endif ()

