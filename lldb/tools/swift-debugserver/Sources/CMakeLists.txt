add_subdirectory(Core)
add_subdirectory(Host)

# Driver must be added last because it links everything else.
add_subdirectory(Driver)
