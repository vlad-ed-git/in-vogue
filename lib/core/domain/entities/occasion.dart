/// What an outfit is for.
enum Occasion {
  work,
  casual,
  goingOut,
  stayingIn;

  /// The default for [date]: work on weekdays, casual at the weekend.
  static Occasion defaultFor(DateTime date) =>
      date.weekday >= DateTime.saturday ? casual : work;
}
