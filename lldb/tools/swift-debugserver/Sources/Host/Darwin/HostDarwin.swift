import Darwin

public struct HostDarwin: HostInterface {
  public static func isolateSession() throws(SessionIsolationError) {
    let sid = setsid()
    // EPERM indicates this is already a process group leader which is
    // not a problem.
    if sid == -1 && errno != EPERM {
      throw .failure(errno)
    }
  }
}
