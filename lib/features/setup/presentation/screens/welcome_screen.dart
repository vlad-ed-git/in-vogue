import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/features/location/presentation/bloc/location_bloc.dart';

/// Setup step 1: who In Vogue is for, and the one permission it needs.
///
/// A refusal replaces the button with the location notice; returning from
/// the phone's settings checks again without asking.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({required this.onLocated, super.key});

  /// Called once the location is found and saved.
  final VoidCallback onLocated;

  /// The In Vogue logo, the app icon's artwork.
  static const logo = AssetImage('assets/images/logo.png');

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => _bloc.add(LocationRechecked(_languageCode)),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  LocationBloc get _bloc => context.read<LocationBloc>();

  String get _languageCode => Localizations.localeOf(context).languageCode;

  void _locate() => _bloc.add(LocationRequested(_languageCode));

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    return BlocListener<LocationBloc, LocationState>(
      listenWhen: (previous, current) =>
          previous.status != LocationStatus.located &&
          current.status == LocationStatus.located,
      listener: (context, state) => widget.onLocated(),
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: InVogueSpace.s6),
                    // The logo as a square in the height the text leaves, so
                    // the button stays in the first view; scrolls below the
                    // minimum.
                    Expanded(
                      child: PageMargin(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: _logoMin,
                          ),
                          child: Semantics(
                            image: true,
                            label: l10n.appName,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: WelcomeScreen.logo,
                                  fit: BoxFit.contain,
                                  alignment: AlignmentDirectional.topStart,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    PageMargin(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: InVogueSpace.s6),
                          ScreenTitle(
                            l10n.tagline,
                            style: InVogueType.headline,
                          ),
                          const SizedBox(height: InVogueSpace.s3),
                          Text(
                            l10n.welcomeDescription,
                            style: InVogueType.body.copyWith(
                              color: InVogueColors.graphite,
                            ),
                          ),
                          const SizedBox(height: InVogueSpace.s5),
                          BlocBuilder<LocationBloc, LocationState>(
                            builder: (context, state) => _action(state),
                          ),
                          const SizedBox(height: InVogueSpace.s4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(LocationState state) {
    if (state.settingsProblem != null) {
      return Notice.locationOff(
        context: context,
        onOpenSettings: () => _bloc.add(const LocationSettingsRequested()),
      );
    }
    final failure = state.failure;
    if (failure != null) {
      return Notice(
        icon: InVogueIcons.warning,
        alert: true,
        message: failure.uiFriendlyMessage(context),
        action: InVogueButton.secondary(
          label: context.translated.retry,
          icon: InVogueIcons.retry,
          onRose: true,
          onPressed: _locate,
        ),
      );
    }
    return InVogueButton.primary(
      label: context.translated.useMyLocation,
      icon: InVogueIcons.mapPin,
      onPressed: state.status == LocationStatus.locating ? null : _locate,
    );
  }
}

const double _logoMin = 160;
