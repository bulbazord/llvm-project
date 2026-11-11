set(host_sources
  Host.swift
  SessionIsolationError.swift
)

if(APPLE)
  list(APPEND host_sources
    Darwin/HostDarwin.swift)
endif()

add_lldb_library(debugserverHost
  ${host_sources}
)
