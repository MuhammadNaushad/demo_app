import 'package:flutter/material.dart';
import 'app_widgets.dart';
import 'place_model.dart';
import 'places_service.dart';

enum FormMode { create, edit }

class PlaceFormScreen extends StatefulWidget {
  final FormMode mode;
  final Place? existing;

  const PlaceFormScreen({
    super.key,
    required this.mode,
    this.existing,
  });

  @override
  State<PlaceFormScreen> createState() => _PlaceFormScreenState();
}

class _PlaceFormScreenState extends State<PlaceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _imageUrl;
  late final TextEditingController _state;
  late final TextEditingController _city;
  late final TextEditingController _country;

  bool _isSaving = false;

  bool get _isEdit => widget.mode == FormMode.edit;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _latitude =
        TextEditingController(text: p != null ? '${p.latitude}' : '');
    _longitude =
        TextEditingController(text: p != null ? '${p.longitude}' : '');
    _imageUrl = TextEditingController(text: p?.imageUrl ?? '');
    _state = TextEditingController(text: p?.state ?? '');
    _city = TextEditingController(text: p?.city ?? '');
    _country = TextEditingController(text: p?.country ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _name, _description, _latitude, _longitude,
      _imageUrl, _state, _city, _country,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final payload = Place(
      id: widget.existing?.id ?? 0,
      name: _name.text.trim(),
      description: _description.text.trim(),
      latitude: double.parse(_latitude.text.trim()),
      longitude: double.parse(_longitude.text.trim()),
      imageUrl:
          _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      state: _state.text.trim(),
      city: _city.text.trim(),
      country: _country.text.trim(),
    );

    try {
      Place saved;
      if (_isEdit) {
        saved =
            await PlacesService.updatePlace(widget.existing!.id, payload);
      } else {
        saved = await PlacesService.createPlace(payload);
      }
      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        showErrorSnack(
            context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: AppColors.textPrimary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEdit ? 'EDIT' : 'NEW',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        ),
                      ),
                      Text(
                        _isEdit ? 'Update Place' : 'Create Place',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Form ───────────────────────────────────────────────────
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section label
                      _sectionLabel('Basic Info'),
                      const SizedBox(height: 12),

                      AppTextField(
                        label: 'Name',
                        hint: 'e.g. Maharaj Bagh',
                        controller: _name,
                        prefixIcon: const Icon(Icons.label_rounded),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        label: 'Description',
                        hint: 'Describe the place…',
                        controller: _description,
                        maxLines: 3,
                        prefixIcon: const Icon(Icons.notes_rounded),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Description is required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        label: 'Image URL (optional)',
                        hint: 'https://example.com/image.jpg',
                        controller: _imageUrl,
                        keyboardType: TextInputType.url,
                        prefixIcon: const Icon(Icons.image_rounded),
                      ),

                      const SizedBox(height: 28),
                      _sectionLabel('Location'),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'City',
                              hint: 'Nagpur',
                              controller: _city,
                              prefixIcon:
                                  const Icon(Icons.location_city_rounded),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Required'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              label: 'State',
                              hint: 'Maharashtra',
                              controller: _state,
                              prefixIcon: const Icon(Icons.map_rounded),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Required'
                                      : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        label: 'Country',
                        hint: 'India',
                        controller: _country,
                        prefixIcon: const Icon(Icons.public_rounded),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Country is required'
                            : null,
                      ),

                      const SizedBox(height: 28),
                      _sectionLabel('Coordinates'),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Latitude',
                              hint: '42.6114',
                              controller: _latitude,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true, signed: true),
                              prefixIcon:
                                  const Icon(Icons.south_rounded),
                              validator: _coordValidator,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              label: 'Longitude',
                              hint: '-89.5399',
                              controller: _longitude,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true, signed: true),
                              prefixIcon:
                                  const Icon(Icons.east_rounded),
                              validator: _coordValidator,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      AppButton(
                        label: _isEdit ? 'Save Changes' : 'Create Place',
                        onTap: _submit,
                        isLoading: _isSaving,
                        icon: _isEdit
                            ? Icons.save_rounded
                            : Icons.add_location_alt_rounded,
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _coordValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
    return null;
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
