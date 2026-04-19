import 'package:flutter/material.dart';
import 'app_widgets.dart';
import 'place_model.dart';
import 'places_service.dart';
import 'place_form_screen.dart';

class PlaceDetailScreen extends StatefulWidget {
  final int placeId;
  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  Place? _place;
  bool _isLoading = true;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlace();
  }

  Future<void> _loadPlace() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final place = await PlacesService.fetchPlace(widget.placeId);
      setState(() {
        _place = place;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _openEdit() async {
    if (_place == null) return;
    final updated = await Navigator.push<Place>(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceFormScreen(mode: FormMode.edit, existing: _place),
      ),
    );
    if (updated != null) {
      // Preserve images since edit response may not include them
      setState(() => _place = updated.copyWith(images: _place!.images));
      if (mounted) showSuccessSnack(context, 'Place updated successfully');
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Place',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${_place!.name}"? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) _deletePlace();
  }

  Future<void> _deletePlace() async {
    setState(() => _isDeleting = true);
    try {
      await PlacesService.deletePlace(widget.placeId);
      if (mounted) {
        showSuccessSnack(context, '"${_place!.name}" deleted');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  // ── Image actions (wire up once you share endpoints) ────────────────────

  Future<void> _addImage() async {
    // TODO: connect to POST /api/v1/places/:id/images
    // After upload, call _loadPlace() to refresh
    showSuccessSnack(context, 'Image upload coming soon!');
  }

  Future<void> _deleteImage(PlaceImage image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Image',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Remove this image from the place?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await PlacesService.deleteImage(widget.placeId, image.id);
      setState(() {
        _place = _place!.copyWith(
          images: _place!.images.where((img) => img.id != image.id).toList(),
        );
      });
      if (mounted) showSuccessSnack(context, 'Image removed');
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _openFullscreen(List<PlaceImage> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _FullscreenGallery(images: images, initialIndex: initialIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _isLoading
            ? _buildLoader()
            : _errorMessage != null
            ? _buildError()
            : _buildDetail(),
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.border,
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 52,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(label: 'Retry', onTap: _loadPlace),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail() {
    final p = _place!;
    return Column(
      children: [
        // ── App Bar ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _iconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              _iconBtn(
                icon: Icons.edit_rounded,
                onTap: _openEdit,
                color: AppColors.accent,
              ),
              const SizedBox(width: 10),
              _iconBtn(
                icon: _isDeleting ? null : Icons.delete_rounded,
                onTap: _isDeleting ? null : _confirmDelete,
                color: AppColors.error,
                isLoading: _isDeleting,
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(p),
                const SizedBox(height: 24),
                if (p.description.isNotEmpty) ...[
                  _buildDescription(p.description),
                  const SizedBox(height: 24),
                ],
                _buildImagesSection(p),
                const SizedBox(height: 24),
                _buildDetailsCard(p),
                const SizedBox(height: 16),
                if (p.createdAt != null) _buildTimestamps(p),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────

  Widget _buildHeroCard(Place p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withOpacity(0.15), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ID #${p.id}',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            p.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${p.city}, ${p.state}, ${p.country}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Description ────────────────────────────────────────────────────────

  Widget _buildDescription(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DESCRIPTION',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  // ── Images Section ─────────────────────────────────────────────────────

  Widget _buildImagesSection(Place p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'PHOTOS',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            if (p.images.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${p.images.length}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const Spacer(),
            GestureDetector(
              onTap: _addImage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      color: AppColors.accent,
                      size: 14,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Add Photo',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (p.images.isEmpty)
          _buildEmptyImages()
        else
          _buildImageGrid(p.images),
      ],
    );
  }

  Widget _buildEmptyImages() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_rounded, color: AppColors.border, size: 40),
          const SizedBox(height: 10),
          const Text(
            'No photos yet',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap "Add Photo" to upload one',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<PlaceImage> images) {
    // Show first image large, rest in a scrollable row
    return Column(
      children: [
        // Featured image
        GestureDetector(
          onTap: () => _openFullscreen(images, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.network(
                  images[0].url,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          height: 200,
                          color: AppColors.surface,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accent,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: AppColors.surface,
                    child: const Icon(
                      Icons.broken_image_rounded,
                      color: AppColors.textMuted,
                      size: 40,
                    ),
                  ),
                ),
                // Delete overlay
                Positioned(top: 8, right: 8, child: _imageDeleteBtn(images[0])),
                // Expand icon
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length - 1,
              itemBuilder: (ctx, i) {
                final img = images[i + 1];
                return GestureDetector(
                  onTap: () => _openFullscreen(images, i + 1),
                  child: Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            img.url,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) =>
                                progress == null
                                ? child
                                : Container(
                                    color: AppColors.surface,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.accent,
                                        strokeWidth: 1.5,
                                      ),
                                    ),
                                  ),
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.surface,
                              child: const Icon(
                                Icons.broken_image_rounded,
                                color: AppColors.textMuted,
                                size: 24,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: _imageDeleteBtn(img, small: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _imageDeleteBtn(PlaceImage image, {bool small = false}) {
    return GestureDetector(
      onTap: () => _deleteImage(image),
      child: Container(
        padding: EdgeInsets.all(small ? 4 : 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(small ? 6 : 8),
        ),
        child: Icon(
          Icons.close_rounded,
          color: Colors.white,
          size: small ? 12 : 16,
        ),
      ),
    );
  }

  // ── Details Card ───────────────────────────────────────────────────────

  Widget _buildDetailsCard(Place p) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          DetailRow(
            icon: Icons.public_rounded,
            label: 'Country',
            value: p.country,
          ),
          _divider(),
          DetailRow(
            icon: Icons.location_city_rounded,
            label: 'State / City',
            value: '${p.state} · ${p.city}',
            iconColor: const Color(0xFF7EB8FF),
          ),
          _divider(),
          DetailRow(
            icon: Icons.my_location_rounded,
            label: 'Coordinates',
            value:
                '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}',
            iconColor: const Color(0xFFFFB74D),
          ),
          if (p.imageUrl != null) ...[
            _divider(),
            DetailRow(
              icon: Icons.image_rounded,
              label: 'Cover Image URL',
              value: p.imageUrl!,
              iconColor: const Color(0xFFA78BFA),
            ),
          ],
        ],
      ),
    );
  }

  // ── Timestamps ─────────────────────────────────────────────────────────

  Widget _buildTimestamps(Place p) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          DetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Created At',
            value: _formatDate(p.createdAt!),
            iconColor: AppColors.textMuted,
          ),
          if (p.updatedAt != null) ...[
            _divider(),
            DetailRow(
              icon: Icons.update_rounded,
              label: 'Updated At',
              value: _formatDate(p.updatedAt!),
              iconColor: AppColors.textMuted,
            ),
          ],
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Widget _iconBtn({
    IconData? icon,
    VoidCallback? onTap,
    Color? color,
    bool isLoading = false,
  }) {
    final c = color ?? AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color != null ? c.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: color != null ? c.withOpacity(0.3) : AppColors.border,
          ),
        ),
        child: isLoading
            ? Padding(
                padding: const EdgeInsets.all(9),
                child: CircularProgressIndicator(strokeWidth: 2, color: c),
              )
            : Icon(icon, color: c, size: 18),
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: AppColors.border, indent: 50);

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Fullscreen Gallery ─────────────────────────────────────────────────────

class _FullscreenGallery extends StatefulWidget {
  final List<PlaceImage> images;
  final int initialIndex;
  const _FullscreenGallery({required this.images, required this.initialIndex});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Page view ────────────────────────────────────────────────
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              return InteractiveViewer(
                child: Center(
                  child: Image.network(
                    widget.images[i].url,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accent,
                              strokeWidth: 2,
                            ),
                          ),
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white54,
                      size: 60,
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Top bar ──────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_current + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Dot indicators ───────────────────────────────────────────
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _current ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _current ? AppColors.accent : Colors.white38,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
