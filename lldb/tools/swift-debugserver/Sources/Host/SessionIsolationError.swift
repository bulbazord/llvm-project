public enum SessionIsolationError: Error {
  case unsupported
  case failure(CInt)
}
