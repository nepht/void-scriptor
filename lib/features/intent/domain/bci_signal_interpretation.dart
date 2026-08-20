class BciInterpretation {
  const BciInterpretation(this.command);

  final String command;

  @override
  bool operator ==(Object other) =>
      other is BciInterpretation && other.command == command;

  @override
  int get hashCode => command.hashCode;
}

class BciSignalInterpreter {
  const BciSignalInterpreter({this.minimumConfidence = .7});

  final double minimumConfidence;

  BciInterpretation? interpret(String command, double confidence) {
    const supported = {'select', 'openWorkspace', 'next', 'previous'};
    if (confidence < minimumConfidence || !supported.contains(command)) {
      return null;
    }
    return BciInterpretation(command);
  }
}
