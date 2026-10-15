/// A screen of first-use setup, in order; [done] once setup is finished.
enum SetupStep {
  welcome,
  photo,

  /// Tomorrow's weather and pieces to pick for it.
  picks,
  signIn,

  /// The person's name and optional face photo.
  profile,
  widget,
  done,
}
