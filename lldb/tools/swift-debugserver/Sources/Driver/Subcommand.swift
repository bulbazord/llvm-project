import debugserverCore

protocol Subcommand {
  static var helpText: String { get }

  static func parse(_ args: ArraySlice<String>) throws(ArgumentParseError) -> Self

  func run() throws(DebugServerError)
}

extension Subcommand {
  static func run(_ args: ArraySlice<String>) {
    let command: Self
    do {
      command = try parse(args)
    } catch {
      switch error {
      case .failure(let message):
        print(message)
      case .unexpectedArgument(let arg):
        print("Unexpected argument: \(arg)")
      }
      print(helpText)
      return
    }

    do {
      try command.run()
    } catch {
      switch error {
      case .failure(let message):
        print(message)
      }
    }
  }
}
