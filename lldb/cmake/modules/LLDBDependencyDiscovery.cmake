# This module implements lldb_discover_dependencies(), used when
# LLDB_DEPENDENCY_DISCOVERY_ONLY is set. It walks the CMake target graph
# produced by a normal LLDB standalone configure and emits the LLVM/Clang and
# Swift target names LLDB actually needs, without building anything. See the
# option's definition in lldb/CMakeLists.txt for the full rationale.
#
# The target list is derived entirely from CMake target properties (which
# targets LLDB's own targets link against/depend on, and where those
# targets' build artifacts live) rather than a maintained list, so it tracks
# LLDB's real dependencies as they change over time.

# Recursively collects every target defined anywhere under a source
# directory tree. The SUBDIRECTORIES directory property only reports
# immediate children, so this walks it by hand.
function(lldb_discovery_collect_targets dir out_var)
  set(result "")
  get_property(dir_targets DIRECTORY "${dir}" PROPERTY BUILDSYSTEM_TARGETS)
  list(APPEND result ${dir_targets})
  get_property(subdirs DIRECTORY "${dir}" PROPERTY SUBDIRECTORIES)
  foreach(subdir ${subdirs})
    lldb_discovery_collect_targets("${subdir}" sub_result)
    list(APPEND result ${sub_result})
  endforeach()
  set(${out_var} "${result}" PARENT_SCOPE)
endfunction()

# TRUE in <out_var> if <path> starts with <prefix>. Uses string(FIND) rather
# than MATCHES: MATCHES is a regex match, and paths routinely contain regex
# metacharacters (e.g. periods in version numbers) that would otherwise be
# silently misinterpreted as pattern syntax.
function(lldb_discovery_path_has_prefix path prefix out_var)
  set(${out_var} FALSE PARENT_SCOPE)
  if("${path}" STREQUAL "" OR "${prefix}" STREQUAL "")
    return()
  endif()
  string(FIND "${path}" "${prefix}" idx)
  if(idx EQUAL 0)
    set(${out_var} TRUE PARENT_SCOPE)
  endif()
endfunction()

# Resolves the on-disk artifact path for an imported target, if it has one.
# Plain (non-imported) targets built as part of LLDB's own project don't set
# these properties, so this naturally returns empty for LLDB's own targets.
function(lldb_discovery_resolve_location target out_var)
  set(${out_var} "" PARENT_SCOPE)
  get_target_property(loc "${target}" IMPORTED_LOCATION)
  if(loc)
    set(${out_var} "${loc}" PARENT_SCOPE)
    return()
  endif()
  foreach(config NOCONFIG DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
    get_target_property(loc "${target}" IMPORTED_LOCATION_${config})
    if(loc)
      set(${out_var} "${loc}" PARENT_SCOPE)
      return()
    endif()
  endforeach()
endfunction()

function(lldb_discover_dependencies)
  message(STATUS "LLDB dependency discovery: collecting LLDB's own targets")
  lldb_discovery_collect_targets("${CMAKE_CURRENT_SOURCE_DIR}" root_targets)
  list(REMOVE_DUPLICATES root_targets)

  # Transitive walk, adapted from the pattern used by export_executable_symbols
  # in llvm/cmake/modules/AddLLVM.cmake: start from a frontier of targets,
  # expand it one edge at a time via link/dependency properties, and stop
  # once nothing new is discovered.
  set(visited "")
  set(frontier "${root_targets}")
  set(llvm_clang_targets "")
  set(swift_targets "")

  while(NOT "${frontier}" STREQUAL "")
    set(next_frontier "")
    foreach(target ${frontier})
      if(NOT TARGET "${target}" OR "${target}" IN_LIST visited)
        continue()
      endif()
      list(APPEND visited "${target}")

      lldb_discovery_resolve_location("${target}" loc)
      if(loc)
        lldb_discovery_path_has_prefix("${loc}" "${LLVM_BINARY_DIR}" is_llvm)
        if(is_llvm)
          list(APPEND llvm_clang_targets "${target}")
        endif()
        if(LLDB_ENABLE_SWIFT_SUPPORT)
          lldb_discovery_path_has_prefix("${loc}" "${SWIFT_BINARY_DIR}" is_swift)
          if(is_swift)
            list(APPEND swift_targets "${target}")
          endif()
        endif()
      endif()

      foreach(prop LINK_LIBRARIES INTERFACE_LINK_LIBRARIES MANUALLY_ADDED_DEPENDENCIES)
        get_target_property(deps "${target}" ${prop})
        if(NOT deps)
          continue()
        endif()
        foreach(dep ${deps})
          # Exported/imported link libraries commonly wrap private
          # dependencies as $<LINK_ONLY:name>; unwrap it so the walk can
          # still follow it. Other generator expressions aren't targets and
          # are dropped by the TARGET check above.
          string(REGEX REPLACE "^\\$<LINK_ONLY:(.+)>$" "\\1" dep "${dep}")
          if(TARGET "${dep}" AND NOT "${dep}" IN_LIST visited)
            list(APPEND next_frontier "${dep}")
          endif()
        endforeach()
      endforeach()
    endforeach()
    list(REMOVE_DUPLICATES next_frontier)
    set(frontier "${next_frontier}")
  endwhile()

  list(REMOVE_DUPLICATES llvm_clang_targets)
  list(SORT llvm_clang_targets)
  list(REMOVE_DUPLICATES swift_targets)
  list(SORT swift_targets)

  set(llvm_out "${CMAKE_BINARY_DIR}/lldb-discovered-llvm-targets.txt")
  set(swift_out "${CMAKE_BINARY_DIR}/lldb-discovered-swift-targets.txt")
  string(REPLACE ";" "\n" llvm_out_contents "${llvm_clang_targets}")
  string(REPLACE ";" "\n" swift_out_contents "${swift_targets}")
  file(WRITE "${llvm_out}" "${llvm_out_contents}\n")
  file(WRITE "${swift_out}" "${swift_out_contents}\n")

  list(LENGTH llvm_clang_targets llvm_count)
  list(LENGTH swift_targets swift_count)
  message(STATUS "LLDB dependency discovery: wrote ${llvm_count} LLVM/Clang target(s) to ${llvm_out}")
  message(STATUS "LLDB dependency discovery: wrote ${swift_count} Swift target(s) to ${swift_out}")
endfunction()
