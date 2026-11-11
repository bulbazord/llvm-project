#if os(anyAppleOS)
public typealias Host = HostDarwin
#else
#error("Unsupported host")
#endif

public protocol HostInterface {
  static func isolateSession() throws(SessionIsolationError)
}
