import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/core/utils/occasion_l10n.dart';
import 'package:in_vogue/features/wardrobe/domain/entities/wardrobe_outfit.dart';
import 'package:in_vogue/features/wardrobe/presentation/bloc/add_outfit_bloc.dart';
import 'package:in_vogue/features/wardrobe/presentation/wardrobe_text.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';

/// Adds an outfit the person owns: a photo from Photos or Gallery, its
/// name, its colours, the weather and the occasions it suits.
class AddOutfitScreen extends StatefulWidget {
  const AddOutfitScreen({required this.onDone, super.key});

  /// Called on Back, and once the outfit is saved.
  final VoidCallback onDone;

  @override
  State<AddOutfitScreen> createState() => _AddOutfitScreenState();
}

class _AddOutfitScreenState extends State<AddOutfitScreen> {
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.addListener(
      () => context.read<AddOutfitBloc>().add(AddOutfitNameChanged(_name.text)),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    return BlocListener<AddOutfitBloc, AddOutfitState>(
      listenWhen: (previous, current) => !previous.saved && current.saved,
      listener: (context, state) => widget.onDone(),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: PageMargin(
              child: BlocBuilder<AddOutfitBloc, AddOutfitState>(
                builder: (context, state) {
                  final bloc = context.read<AddOutfitBloc>();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BackBar(onBack: widget.onDone),
                      const SizedBox(height: InVogueSpace.s3),
                      ScreenTitle(l10n.addOutfit),
                      const SizedBox(height: InVogueSpace.s3),
                      Text(
                        l10n.addOutfitLine,
                        style: InVogueType.body.copyWith(
                          color: InVogueColors.graphite,
                        ),
                      ),
                      const SizedBox(height: InVogueSpace.s6),
                      ..._photo(context, state),
                      const SizedBox(height: InVogueSpace.s6),
                      InVogueTextField(
                        label: l10n.outfitName,
                        controller: _name,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      SectionHeading(l10n.outfitColours),
                      _ColourChoice(
                        chosen: state.colours,
                        onToggled: (colour) =>
                            bloc.add(AddOutfitColourToggled(colour)),
                      ),
                      SectionHeading(l10n.outfitWeather),
                      ChoiceChips(
                        semanticLabel: l10n.outfitWeather,
                        labels: [
                          for (final band in WarmthBand.values)
                            band.label(l10n),
                          l10n.weatherRain,
                        ],
                        selected: {
                          for (final band in state.bands) band.index,
                          if (state.rain) WarmthBand.values.length,
                        },
                        onToggled: (index) => bloc.add(
                          index == WarmthBand.values.length
                              ? const AddOutfitRainToggled()
                              : AddOutfitBandToggled(WarmthBand.values[index]),
                        ),
                      ),
                      SectionHeading(l10n.outfitOccasion),
                      ChoiceChips(
                        semanticLabel: l10n.outfitOccasion,
                        labels: [
                          for (final occasion in Occasion.values)
                            occasion.label(l10n),
                        ],
                        selected: {
                          for (final occasion in state.occasions)
                            occasion.index,
                        },
                        onToggled: (index) => bloc.add(
                          AddOutfitOccasionToggled(Occasion.values[index]),
                        ),
                      ),
                      if (state.failure case final failure?
                          when failure is! PhotoFailure) ...[
                        const SizedBox(height: InVogueSpace.s6),
                        Notice(
                          icon: InVogueIcons.warning,
                          alert: true,
                          message: failure.uiFriendlyMessage(context),
                        ),
                      ],
                      const SizedBox(height: InVogueSpace.s8),
                      InVogueButton.primary(
                        label: l10n.saveOutfit,
                        icon: InVogueIcons.check,
                        busy: state.saving,
                        onPressed: state.canSave
                            ? () => bloc.add(const AddOutfitSaved())
                            : null,
                      ),
                      const SizedBox(height: InVogueSpace.s6),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _photo(BuildContext context, AddOutfitState state) {
    final l10n = context.translated;
    final bloc = context.read<AddOutfitBloc>();
    final photo = state.photo;
    return [
      FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 0.5,
        child: PhotoSlot(
          image: photo == null ? null : FileImage(File(photo)),
          fit: BoxFit.contain,
          background: photo == null
              ? InVogueColors.accent
              : InVogueColors.paper,
          semanticLabel: photo == null ? null : l10n.yourPhoto,
        ),
      ),
      const SizedBox(height: InVogueSpace.s4),
      if (photo == null)
        InVogueButton.secondary(
          label: context.isApplePlatform
              ? l10n.chooseFromPhotos
              : l10n.chooseFromGallery,
          icon: InVogueIcons.image,
          busy: state.choosing,
          onPressed: () => bloc.add(const AddOutfitPhotoRequested()),
        )
      else
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextLink(
            label: l10n.chooseDifferentPhoto,
            busy: state.choosing,
            onTap: () => bloc.add(const AddOutfitPhotoRequested()),
          ),
        ),
      if (state.converted && photo != null)
        Padding(
          padding: const EdgeInsets.only(top: InVogueSpace.s4),
          child: Notice(icon: InVogueIcons.image, message: l10n.photoConverted),
        ),
      if (state.failure case final PhotoFailure failure)
        Padding(
          padding: const EdgeInsets.only(top: InVogueSpace.s4),
          child: Notice(
            icon: InVogueIcons.warning,
            alert: true,
            message: failure.uiFriendlyMessage(context),
          ),
        ),
    ];
  }
}

/// The outfit colours as round swatches; any number are chosen.
class _ColourChoice extends StatelessWidget {
  const _ColourChoice({required this.chosen, required this.onToggled});

  final Set<OutfitColour> chosen;
  final ValueChanged<OutfitColour> onToggled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    return Wrap(
      spacing: InVogueSpace.s1,
      runSpacing: InVogueSpace.s1,
      children: [
        for (final colour in OutfitColour.values)
          Pressable(
            onTap: () => onToggled(colour),
            toggled: chosen.contains(colour),
            haptic: InVogueHaptic.selection,
            semanticLabel: colour.label(l10n),
            excludeSemantics: true,
            builder: (context, state) => SizedBox.square(
              dimension: context.minTapTarget,
              child: Center(
                child: Swatch(
                  color: Color(colour.argb),
                  size: Swatch.large,
                  selected: chosen.contains(colour),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
