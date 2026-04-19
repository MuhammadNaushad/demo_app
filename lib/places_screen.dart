import 'package:flutter/material.dart';
import 'app_widgets.dart';
import 'place_model.dart';
import 'places_service.dart';
import 'place_detail_screen.dart';
import 'place_form_screen.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen>
    with SingleTickerProviderStateMixin {
  List<Place> _places = [];
  List<Place> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchCtrl = TextEditingController();
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _searchCtrl.addListener(_onSearch);
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final places = await PlacesService.fetchPlaces();
      setState(() {
        _places = places;
        _filtered = List.from(places);
        _isLoading = false;
      });
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_places)
          : _places
              .where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.city.toLowerCase().contains(q) ||
                  p.country.toLowerCase().contains(q) ||
                  p.state.toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<Place>(
      context,
      MaterialPageRoute(
        builder: (_) => const PlaceFormScreen(mode: FormMode.create),
      ),
    );
    if (created != null) {
      _loadPlaces();
      if (mounted) showSuccessSnack(context, '"${created.name}" created!');
    }
  }

  Future<void> _openDetail(Place place) async {
    final result = await Navigator.push<_ListAction>(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceDetailScreen(placeId: place.id),
      ),
    );
    if (result != null) _loadPlaces();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add_rounded, color: AppColors.bg, size: 26),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (!_isLoading && _errorMessage == null) ...[
              _buildSearchBar(),
              _buildStats(),
            ],
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EXPLORE',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Places',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _isLoading ? null : _loadPlaces,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A3550)),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded,
                      color: AppColors.accent, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search_rounded,
                color: AppColors.textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search by name, city, state…',
                  hintStyle:
                      TextStyle(color: AppColors.textMuted, fontSize: 14),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                cursorColor: AppColors.accent,
              ),
            ),
            if (_searchCtrl.text.isNotEmpty)
              GestureDetector(
                onTap: () => _searchCtrl.clear(),
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.close_rounded,
                      color: AppColors.textMuted, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        '${_filtered.length} location${_filtered.length == 1 ? '' : 's'} found',
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoader();
    if (_errorMessage != null) return _buildError();
    return _buildList();
  }

  Widget _buildLoader() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.accent,
              backgroundColor: AppColors.border,
            ),
          ),
          SizedBox(height: 20),
          Text('Fetching places…',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: AppColors.error, size: 30),
            ),
            const SizedBox(height: 16),
            const Text('Failed to load places',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 24),
            AppButton(
              label: 'Try Again',
              onTap: _loadPlaces,
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_rounded,
                color: AppColors.border, size: 56),
            const SizedBox(height: 16),
            Text(
              _searchCtrl.text.isNotEmpty
                  ? 'No results for "${_searchCtrl.text}"'
                  : 'No places yet. Tap + to add one.',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 96),
      itemCount: _filtered.length,
      itemBuilder: (ctx, i) {
        final place = _filtered[i];
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: _fadeCtrl,
            curve: Interval((i * 0.07).clamp(0.0, 0.8), 1.0,
                curve: Curves.easeOut),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _fadeCtrl,
              curve: Interval((i * 0.07).clamp(0.0, 0.8), 1.0,
                  curve: Curves.easeOut),
            )),
            child: _PlaceCard(
              place: place,
              onTap: () => _openDetail(place),
            ),
          ),
        );
      },
    );
  }
}

// ── Internal signal type ───────────────────────────────────────────────────
enum _ListAction { updated, deleted }

// ── Place Card ─────────────────────────────────────────────────────────────
class _PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  const _PlaceCard({required this.place, required this.onTap});

  Color _accent() {
    const colors = [
      AppColors.accent,
      Color(0xFF7EB8FF),
      Color(0xFFFFB74D),
      Color(0xFFFF7EB3),
      Color(0xFFA78BFA),
      Color(0xFF67E8F9),
    ];
    return colors[place.id % colors.length];
  }

  String _fmt(double v) => '${v.abs().toStringAsFixed(4)}°';

  @override
  Widget build(BuildContext context) {
    final accent = _accent();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: accent.withOpacity(0.08),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.place_rounded, color: accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2)),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.location_city_rounded,
                            color: AppColors.textMuted, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${place.city}, ${place.state}, ${place.country}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        _Chip(
                          label:
                              '${_fmt(place.latitude)} ${place.latitude >= 0 ? 'N' : 'S'}',
                          accent: accent,
                        ),
                        const SizedBox(width: 6),
                        _Chip(
                          label:
                              '${_fmt(place.longitude)} ${place.longitude >= 0 ? 'E' : 'W'}',
                          accent: accent,
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      color: accent, size: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color accent;
  const _Chip({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Text(label,
          style: TextStyle(
              color: accent.withOpacity(0.9),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2)),
    );
  }
}
