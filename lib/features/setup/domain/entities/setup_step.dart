/// A screen of first-use setup, in order; [done] once setup is finished.
enum SetupStep {
  welcome,
  photo,
  firstOutfit,
  picks,
  signIn,
  name,
  facePhoto,
  widget,

  /// The iPhone's three steps for adding the widget.
  widgetSteps,
  done,
}
