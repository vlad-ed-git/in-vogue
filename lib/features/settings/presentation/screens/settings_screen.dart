import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/features/account/domain/entities/account_plan.dart';
import 'package:in_vogue/features/account/presentation/bloc/delete_account_bloc.dart';
import 'package:in_vogue/features/auth/presentation/bloc/log_out_bloc.dart';
import 'package:in_vogue/features/location/presentation/bloc/location_bloc.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:in_vogue/features/preferences/presentation/widgets/language_row.dart';
import 'package:in_vogue/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:in_vogue/features/settings/presentation/bloc/settings_bloc.dart';

/// The Settings tab: hairline rows of what the person can change.
///
/// The face photo's [PhotoBloc] is above the screen; the body photo's is
/// made for its row by [bodyPhoto].
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.onLoggedOut,
    required this.onAccountDeleted,
    required this.bodyPhoto,
    required this.onAddWidget,
    super.key,
  });

  /// Called once the person is logged out.
  final VoidCallback onLoggedOut;

  /// Called once the account is deleted.
  final VoidCallback onAccountDeleted;

  /// Makes the body photo's bloc.
  final PhotoBloc Function() bodyPhoto;

  /// Asks the launcher to place the widget; false when it can't.
  final Future<bool> Function() onAddWidget;

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<LogOutBloc, LogOutState>(
        listenWhen: (previous, current) => previous != current,
        listener: (context, state) {
          if (state.status == LogOutStatus.loggedOut) onLoggedOut();
          if (state.failure != null) _fail(context, state.failure!);
        },
      ),
      BlocListener<DeleteAccountBloc, DeleteAccountState>(
        listenWhen: (previous, current) => previous != current,
        listener: (context, state) {
          if (state.status == DeleteAccountStatus.deleted) onAccountDeleted();
          if (state.failure != null) _fail(context, state.failure!);
        },
      ),
      BlocListener<SettingsBloc, SettingsState>(
        listenWhen: (previous, current) =>
            current.failure != null && previous.failure != current.failure,
        listener: (context, state) => _fail(context, state.failure!),
      ),
      BlocListener<LocationBloc, LocationState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == LocationStatus.located) {
            context.read<SettingsBloc>().add(const SettingsSetupChanged());
          }
          if (state.failure != null) _fail(context, state.failure!);
        },
      ),
    ],
    child: SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: PageMargin(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: InVogueSpace.s4),
              ScreenTitle(context.translated.tabSettings),
              const SizedBox(height: InVogueSpace.s6),
              SettingsRows(
                children: [
                  const _ProfileRow(),
                  BlocProvider(
                    create: (_) => bodyPhoto()..add(const PhotoLoaded()),
                    child: const _PhotoRow(PhotoRole.body),
                  ),
                  const _PhotoRow(PhotoRole.face),
                  const _MembershipRow(),
                  const _LocationRow(),
                  const _DefaultDayRow(),
                  const LanguageRow(),
                  _WidgetRow(onAddWidget),
                  BlocBuilder<LogOutBloc, LogOutState>(
                    builder: (context, state) => SettingsRow.logOut(
                      context,
                      state.status == LogOutStatus.idle
                          ? () => context.read<LogOutBloc>().add(
                              const LogOutRequested(),
                            )
                          : null,
                    ),
                  ),
                  BlocBuilder<DeleteAccountBloc, DeleteAccountState>(
                    builder: (context, state) =>
                        SettingsRow.deleteAccount(context, () async {
                          if (state.status != DeleteAccountStatus.idle) return;
                          final bloc = context.read<DeleteAccountBloc>();
                          if (await _confirmDelete(context)) {
                            bloc.add(const DeleteAccountConfirmed());
                          }
                        }),
                  ),
                ],
              ),
              const SizedBox(height: InVogueSpace.s10),
            ],
          ),
        ),
      ),
    ),
  );

  /// Asks once more before deleting the account; true to delete.
  static Future<bool> _confirmDelete(BuildContext context) async {
    final delete = await showInVogueSheet<bool>(
      context: context,
      builder: (context) {
        final l10n = context.translated;
        return InVogueSheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InVogueSheetHeader(title: l10n.deleteAccountTitle),
              Text(
                l10n.deleteAccountLine,
                style: InVogueType.body.copyWith(color: InVogueColors.graphite),
              ),
              const SizedBox(height: InVogueSpace.s6),
              InVogueButton.primary(
                label: l10n.deleteAccount,
                icon: InVogueIcons.trash,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: InVogueSpace.s3),
              InVogueButton.secondary(
                label: l10n.keepAccount,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        );
      },
    );
    return delete ?? false;
  }

  static void _fail(BuildContext context, Failure failure) => context.showSnack(
    message: failure.uiFriendlyMessage(context),
    isError: true,
  );
}

/// The face photo, the name and how the person signed in; Edit changes
/// the name.
class _ProfileRow extends StatelessWidget {
  const _ProfileRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final face = context.select<PhotoBloc, String?>((bloc) => bloc.state.path);
    final method = context.select<SettingsBloc, String?>(
      (bloc) => bloc.state.account?.method?.name,
    );
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, profile) => SettingsRow.profile(
        title: profile.name,
        avatar: face == null ? null : FileImage(File(face)),
        value: method == null ? null : l10n.signedInWith(method),
        action: l10n.edit,
        onAction: profile.status == ProfileStatus.saving
            ? null
            : () async {
                final bloc = context.read<ProfileBloc>();
                final name = await _editName(context, profile.name);
                if (name != null) bloc.add(ProfileNameSaved(name));
              },
      ),
    );
  }

  static Future<String?> _editName(BuildContext context, String name) =>
      showInVogueSheet<String>(
        context: context,
        builder: (context) => _NameSheet(name: name),
      );
}

class _NameSheet extends StatefulWidget {
  const _NameSheet({required this.name});

  final String name;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.name)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;
    Navigator.of(context).pop(_name.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    return InVogueSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InVogueSheetHeader(title: l10n.aboutYouTitle),
          InVogueTextField(
            label: l10n.yourName,
            controller: _name,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: InVogueSpace.s4),
          InVogueButton.primary(
            label: l10n.save,
            icon: InVogueIcons.check,
            onPressed: _name.text.trim().isEmpty ? null : _save,
          ),
        ],
      ),
    );
  }
}

/// A photo of the person; Replace (or Add) chooses another and keeps it.
class _PhotoRow extends StatelessWidget {
  const _PhotoRow(this.role);

  final PhotoRole role;

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    return BlocConsumer<PhotoBloc, PhotoState>(
      listener: (context, state) {
        if (state.status == PhotoStatus.chosen &&
            !state.isKept &&
            !state.busy) {
          context.read<PhotoBloc>().add(const PhotoConfirmed());
        }
        if (state.status == PhotoStatus.confirmed) {
          context.read<SettingsBloc>().add(const SettingsSetupChanged());
          if (state.converted) context.showSnack(message: l10n.photoConverted);
        }
        if (state.failure != null) {
          SettingsScreen._fail(context, state.failure!);
        }
      },
      listenWhen: (previous, current) => previous != current,
      builder: (context, state) {
        final has = state.path != null;
        return SettingsRow(
          title: role == PhotoRole.body ? l10n.bodyPhoto : l10n.facePhoto,
          value: !has
              ? l10n.notAdded
              : role == PhotoRole.body
              ? l10n.bodyPhotoUse
              : l10n.facePhotoUse,
          action: has ? l10n.replace : l10n.add,
          onAction: state.busy
              ? null
              : () =>
                    context.read<PhotoBloc>().add(const PhotoChooseRequested()),
        );
      },
    );
  }
}

/// Pro or the free plan.
class _MembershipRow extends StatelessWidget {
  const _MembershipRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final plan = context.select<SettingsBloc, AccountPlan?>(
      (bloc) => bloc.state.plan,
    );
    return SettingsRow(
      title: l10n.membership,
      value: switch (plan) {
        AccountPlan.pro => l10n.planPro,
        AccountPlan.free => l10n.planFreeName,
        null => null,
      },
    );
  }
}

/// The saved place; Change reads the location again.
class _LocationRow extends StatelessWidget {
  const _LocationRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final city = context.select<SettingsBloc, String?>(
      (bloc) => bloc.state.place?.city,
    );
    final locating = context.select<LocationBloc, bool>(
      (bloc) => bloc.state.status == LocationStatus.locating,
    );
    return SettingsRow(
      title: l10n.location,
      value: city == null ? l10n.locationNotSet : l10n.locationWhileUsing(city),
      action: l10n.change,
      onAction: locating
          ? null
          : () => context.read<LocationBloc>().add(
              LocationRequested(Localizations.localeOf(context).languageCode),
            ),
    );
  }
}

/// The day Home opens on.
class _DefaultDayRow extends StatelessWidget {
  const _DefaultDayRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final day = context.select<SettingsBloc, ForecastDay>(
      (bloc) => bloc.state.defaultDay,
    );
    return SettingsRow(
      title: l10n.defaultDay,
      value: day == ForecastDay.today ? l10n.today : l10n.defaultDayTomorrow,
      action: l10n.change,
      onAction: () async {
        final bloc = context.read<SettingsBloc>();
        final chosen = await showInVogueSheet<ForecastDay>(
          context: context,
          builder: (context) => InVogueSheet(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InVogueSheetHeader(title: l10n.defaultDayTitle),
                for (final option in [ForecastDay.tomorrow, ForecastDay.today])
                  InVogueSheetOption(
                    label: option == ForecastDay.today
                        ? l10n.today
                        : l10n.defaultDayTomorrow,
                    selected: option == day,
                    onTap: () => Navigator.of(context).pop(option),
                  ),
              ],
            ),
          ),
        );
        if (chosen != null && chosen != day) {
          bloc.add(SettingsDefaultDayChanged(chosen));
        }
      },
    );
  }
}

/// The home-screen widget, for anyone who skipped setup's step: Android's
/// launcher places it; when it can't, and on iPhone, a sheet says how.
class _WidgetRow extends StatelessWidget {
  const _WidgetRow(this.onAddWidget);

  final Future<bool> Function() onAddWidget;

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    return SettingsRow(
      title: l10n.homeScreenWidget,
      action: l10n.add,
      onAction: () async {
        final iPhone = context.isApplePlatform;
        if (!iPhone && await onAddWidget()) return;
        if (!context.mounted) return;
        await showInVogueSheet<void>(
          context: context,
          builder: (context) => InVogueSheet(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InVogueSheetHeader(title: l10n.addWidgetTitle),
                if (iPhone)
                  const WidgetSteps()
                else
                  Notice(
                    icon: InVogueIcons.handTap,
                    message: l10n.widgetAddByHand,
                  ),
                const SizedBox(height: InVogueSpace.s6),
                InVogueButton.primary(
                  label: l10n.done,
                  icon: InVogueIcons.check,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
