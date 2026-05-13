enum CheckResult {
  noop,
  allCorrect,
  hasIncorrect;

  bool get shouldVibrate => this == CheckResult.hasIncorrect;
}
