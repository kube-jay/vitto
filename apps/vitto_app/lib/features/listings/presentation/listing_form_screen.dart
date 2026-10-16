import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/config/market.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/picked_image.dart';
import '../../../core/widgets/common.dart';
import '../../auth/data/session_provider.dart';
import '../../profile/data/profile_repository.dart';
import '../data/listing_repository.dart';
import '../domain/listing.dart';
import '../domain/listing_status.dart';
import 'widgets/listing_card.dart';

/// Create or edit a Listing (Part I §6). 1–8 photos; currency follows the
/// Listing country (NG → NGN, BJ → XOF).
class ListingFormScreen extends ConsumerWidget {
  const ListingFormScreen({super.key, this.listingId});

  final String? listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    if (listingId == null) {
      return AsyncBody(
        value: profile,
        onRetry: () => ref.invalidate(myProfileProvider),
        builder: (p) => _ListingForm(
          initialCountry: p?.countryCode ?? 'NG',
          initialRegion: p?.regionCode,
          initialCity: p?.city,
        ),
      );
    }
    return AsyncBody(
      value: ref.watch(listingProvider(listingId!)),
      onRetry: () => ref.invalidate(listingProvider(listingId!)),
      builder: (l) => l == null
          ? EmptyState(
              icon: Icons.inventory_2_outlined,
              title: AppLocalizations.of(context).errListingNotAvailable,
            )
          : _ListingForm(
              existing: l,
              initialCountry: l.countryCode,
              initialRegion: l.regionCode,
              initialCity: l.city,
            ),
    );
  }
}

class _ListingForm extends ConsumerStatefulWidget {
  const _ListingForm({
    this.existing,
    required this.initialCountry,
    this.initialRegion,
    this.initialCity,
  });

  final Listing? existing;
  final String initialCountry;
  final String? initialRegion;
  final String? initialCity;

  @override
  ConsumerState<_ListingForm> createState() => _ListingFormState();
}

/// A photo is either already stored (path) or newly picked (bytes).
class _Photo {
  _Photo.stored(this.path) : picked = null;
  _Photo.picked(this.picked) : path = null;

  final String? path;
  final PickedImage? picked;
}

class _ListingFormState extends ConsumerState<_ListingForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _description = TextEditingController(
    text: widget.existing?.description,
  );
  late final _price = TextEditingController(
    text: widget.existing == null ? '' : _majorText(widget.existing!.price),
  );
  late final _city = TextEditingController(text: widget.initialCity);
  late String _country = widget.initialCountry;
  late String? _region = widget.initialRegion;
  late String? _categoryId = widget.existing?.categoryId;
  late String _condition = widget.existing?.condition ?? 'used';
  late bool _negotiable = widget.existing?.negotiable ?? true;
  late final List<_Photo> _photos = [
    for (final p in widget.existing?.imagePaths ?? const <String>[])
      _Photo.stored(p),
  ];
  final List<String> _removed = [];
  bool _busy = false;

  bool get _isEdit => widget.existing != null;
  String get _currency => Market.fromCountryCode(_country).currencyCode;

  static String _majorText(Money m) {
    final exp = Market.fromCurrencyCode(m.currencyCode).currencyExponent;
    var div = 1;
    for (var i = 0; i < exp; i++) {
      div *= 10;
    }
    final whole = m.minor ~/ div;
    final frac = m.minor % div;
    return frac == 0 ? '$whole' : '$whole.${frac.toString().padLeft(exp, '0')}';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final picked = await pickImages(max: 8 - _photos.length);
    if (!mounted) return;
    if (picked.isEmpty) return;
    setState(() => _photos.addAll(picked.map(_Photo.picked)));
  }

  Future<void> _save({required bool publish}) async {
    final l10n = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return;
    if (publish && _photos.isEmpty) {
      showSnack(context, l10n.validPhotos);
      return;
    }
    final price = Money.tryParse(_price.text, _currency)!;
    final draft = ListingDraft(
      categoryId: _categoryId!,
      title: _title.text,
      description: _description.text,
      priceMinor: price.minor,
      negotiable: _negotiable,
      condition: _condition,
      countryCode: _country,
      regionCode: _region,
      city: _city.text,
    );
    final uid = ref.read(currentUserIdProvider)!;
    final repo = ref.read(listingRepositoryProvider);

    setState(() => _busy = true);
    final id = await runGuarded(context, () async {
      final id = _isEdit ? widget.existing!.id : await repo.create(draft);
      if (_isEdit) await repo.update(id, draft);

      // Upload new photos first so an active Listing never has zero images.
      final ordered = <String>[];
      for (final p in _photos) {
        if (p.path != null) {
          ordered.add(p.path!);
        } else {
          ordered.add(
            await repo.addImage(
              uid: uid,
              listingId: id,
              bytes: p.picked!.bytes,
              mime: p.picked!.mime,
              sortOrder: 7,
            ),
          );
        }
      }
      for (final path in _removed) {
        await repo.removeImage(path);
      }
      await repo.reorderImages(ordered);

      final status = widget.existing?.status ?? ListingStatus.draft;
      if (publish && status != ListingStatus.active) {
        await repo.setStatus(id, ListingStatus.active);
      }
      return id;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (id != null) {
      ref.invalidate(myListingsProvider);
      ref.invalidate(listingProvider(id));
      showSnack(context, publish ? l10n.listingPublished : l10n.saved);
      context.go(Routes.listingPath(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final regions = ref.watch(regionsProvider(_country)).value ?? const [];
    final isActive = widget.existing?.status == ListingStatus.active;

    return Form(
      key: _form,
      child: PageBody(
        children: [
          Text(
            _isEdit ? l10n.screenEditListing : l10n.screenCreateListing,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SectionTitle(l10n.listingImagesCount(_photos.length)),
          Text(
            l10n.photosHint,
            style: const TextStyle(color: VittoColors.muted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _photos.length; i++)
                _PhotoTile(
                  photo: _photos[i],
                  isCover: i == 0,
                  onRemove: () => setState(() {
                    final p = _photos.removeAt(i);
                    if (p.path != null) _removed.add(p.path!);
                  }),
                  onMakeCover: i == 0
                      ? null
                      : () => setState(() {
                          _photos.insert(0, _photos.removeAt(i));
                        }),
                ),
              if (_photos.length < 8)
                InkWell(
                  onTap: _addPhotos,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: VittoColors.field,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: VittoColors.line),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_a_photo_outlined,
                          color: VittoColors.navy,
                        ),
                        const SizedBox(height: 4),
                        Text(l10n.addPhotos),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SectionTitle(l10n.details),
          TextFormField(
            controller: _title,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: l10n.title,
              hintText: l10n.titleHint,
            ),
            validator: (v) =>
                v == null || v.trim().length < 3 ? l10n.validTitle : null,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _categoryId,
            decoration: InputDecoration(labelText: l10n.category),
            items: [
              for (final c in categories)
                DropdownMenuItem(value: c.id, child: Text(c.name(locale))),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
            validator: (v) => v == null ? l10n.validRequired : null,
          ),
          const SizedBox(height: 16),
          Text(l10n.condition),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'new', label: Text(l10n.conditionNew)),
              ButtonSegment(value: 'used', label: Text(l10n.conditionUsed)),
            ],
            selected: {_condition},
            onSelectionChanged: (s) => setState(() => _condition = s.first),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            maxLines: 6,
            maxLength: 5000,
            decoration: InputDecoration(
              labelText: l10n.description,
              hintText: l10n.descriptionHint,
              alignLabelWithHint: true,
            ),
          ),
          SectionTitle(l10n.price),
          TextFormField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.price,
              suffixText: _currency,
            ),
            validator: (v) {
              final m = Money.tryParse(v ?? '', _currency);
              return m == null || m.minor <= 0 ? l10n.validPrice : null;
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _negotiable,
            onChanged: (v) => setState(() => _negotiable = v),
            title: Text(l10n.negotiable),
            subtitle: Text(
              _negotiable ? l10n.negotiableHint : l10n.fixedPriceHint,
            ),
          ),
          SectionTitle(l10n.location),
          DropdownButtonFormField<String>(
            initialValue: _country,
            decoration: InputDecoration(labelText: l10n.country),
            items: [
              DropdownMenuItem(value: 'NG', child: Text(l10n.countryNigeria)),
              DropdownMenuItem(value: 'BJ', child: Text(l10n.countryBenin)),
            ],
            onChanged: (v) => setState(() {
              _country = v!;
              _region = null;
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(_country),
            initialValue: regions.any((r) => r.code == _region)
                ? _region
                : null,
            decoration: InputDecoration(labelText: l10n.region),
            items: [
              for (final r in regions)
                DropdownMenuItem(value: r.code, child: Text(r.name)),
            ],
            onChanged: (v) => setState(() => _region = v),
            validator: (v) => v == null ? l10n.validRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _city,
            decoration: InputDecoration(labelText: l10n.city),
            validator: (v) =>
                v == null || v.trim().isEmpty ? l10n.validRequired : null,
          ),
          const SizedBox(height: 24),
          if (!isActive)
            FilledButton(
              onPressed: _busy ? null : () => _save(publish: true),
              child: Text(l10n.publish),
            ),
          if (!isActive) const SizedBox(height: 8),
          if (isActive)
            FilledButton(
              onPressed: _busy ? null : () => _save(publish: false),
              child: Text(l10n.saveChanges),
            )
          else
            OutlinedButton(
              onPressed: _busy ? null : () => _save(publish: false),
              child: Text(l10n.saveDraft),
            ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.isCover,
    required this.onRemove,
    this.onMakeCover,
  });

  final _Photo photo;
  final bool isCover;
  final VoidCallback onRemove;
  final VoidCallback? onMakeCover;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 104,
      height: 104,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            photo.picked != null
                ? Image.memory(photo.picked!.bytes, fit: BoxFit.cover)
                : ListingImage(path: photo.path),
            Positioned(
              top: 2,
              right: 2,
              child: IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                tooltip: l10n.remove,
                icon: const Icon(Icons.close),
                onPressed: onRemove,
              ),
            ),
            if (isCover)
              Positioned(
                left: 6,
                bottom: 6,
                child: StatusChip(label: l10n.cover, strong: true),
              )
            else
              Positioned(
                left: 2,
                bottom: 2,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white70,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onMakeCover,
                  child: Text(l10n.makeCover),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
