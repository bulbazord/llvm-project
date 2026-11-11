add_lldb_tool(swift-debugserver ADD_TO_FRAMEWORK
  ArgumentParseError.swift
  DebugServer.swift
  GDBServerCommand.swift
  Subcommand.swift
  VersionCommand.swift

  LINK_LIBS
    debugserverCore
    debugserverHost
)

set_target_properties(swift-debugserver PROPERTIES Swift_MODULE_NAME "swift_debugserver")
