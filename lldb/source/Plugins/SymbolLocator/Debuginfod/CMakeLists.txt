lldb_tablegen(SymbolLocatorDebuginfodProperties.inc -gen-lldb-property-defs
  SOURCE SymbolLocatorDebuginfodProperties.td
  TARGET LLDBPluginSymbolLocatorDebuginfodPropertiesGen)

lldb_tablegen(SymbolLocatorDebuginfodPropertiesEnum.inc -gen-lldb-property-enum-defs
  SOURCE SymbolLocatorDebuginfodProperties.td
  TARGET LLDBPluginSymbolLocatorDebuginfodPropertiesEnumGen)

# HACK: LLVMDebuginfod is not a component library but should still only be
# added when not using the swift compiler dylib.
set(_llvm_deps LLVMDebuginfod)
if (LLDB_LINK_SWIFT_COMPILER_DYLIB)
  set(_llvm_deps)
endif()

add_lldb_library(lldbPluginSymbolLocatorDebuginfod PLUGIN
  SymbolLocatorDebuginfod.cpp

  LINK_LIBS
    lldbCore
    lldbHost
    lldbSymbol
    ${_llvm_deps}
  )

if (LLDB_LINK_SWIFT_COMPILER_DYLIB)
  target_link_libraries(lldbPluginSymbolLocatorDebuginfod PRIVATE SwiftCompilerShared)
endif()

add_dependencies(lldbPluginSymbolLocatorDebuginfod
  LLDBPluginSymbolLocatorDebuginfodPropertiesGen
  LLDBPluginSymbolLocatorDebuginfodPropertiesEnumGen)

