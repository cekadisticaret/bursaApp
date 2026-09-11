import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/auth_store.dart';
import '../core/config.dart';
import '../core/theme/app_theme.dart';
import '../widgets/app_page.dart';
import '../widgets/app_refresh.dart';

class BursasporScreen extends StatefulWidget {
  const BursasporScreen({super.key});

  @override
  State<BursasporScreen> createState() => _BursasporScreenState();
}

class _BursasporScreenState extends State<BursasporScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  bool _allFixturesOpen = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthStore>();
      final data = await auth.api.bursasporFeed();
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final desk = (_data['desk'] as Map?)?.cast<String, dynamic>() ?? {};
    final news = (_data['news'] as List? ?? []).cast<Map<String, dynamic>>();
    final videos = (_data['videos'] as List? ?? []).cast<Map<String, dynamic>>();
    final standings = (_data['standings'] as List? ?? []).cast<Map<String, dynamic>>();
    final upcoming = (_data['upcoming'] as List? ?? []).cast<Map<String, dynamic>>();
    final recent = (_data['recent'] as List? ?? []).cast<Map<String, dynamic>>();
    final matches = (_data['matches'] as List? ?? []).cast<Map<String, dynamic>>();
    final nextMatch = (_data['next_match'] as Map?)?.cast<String, dynamic>();
    final bsRow = (_data['bs_row'] as Map?)?.cast<String, dynamic>();
    final form = (desk['form'] as List? ?? []).map((e) => e.toString()).toList();
    final league = _data['league']?.toString() ?? 'Trendyol 1. Lig';
    final heroBg = _data['hero_bg']?.toString() ?? '';
    final generated = _data['generated_at']?.toString() ?? '';

    return AppPage(
      title: 'Bursaspor',
      body: _loading && _data.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : appRefreshList(
              onRefresh: _load,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                _HeroSection(heroBg: heroBg, bsRow: bsRow, form: form, league: league),
                if (nextMatch != null) ...[
                  const SizedBox(height: 14),
                  _NextMatchCard(match: nextMatch),
                ],
                if (desk.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _DeskSection(desk: desk, generated: generated),
                ],
                if (videos.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _VideosSection(videos: videos),
                ],
                if (news.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _NewsSection(news: news),
                ],
                if (standings.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _StandingsSection(standings: standings, league: league),
                ],
                if (upcoming.isNotEmpty || recent.isNotEmpty || matches.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _FixtureSection(
                    upcoming: upcoming,
                    recent: recent,
                    matches: matches,
                    allOpen: _allFixturesOpen,
                    onToggleAll: () => setState(() => _allFixturesOpen = !_allFixturesOpen),
                  ),
                ],
                const SizedBox(height: 12),
                _OfficialLinks(),
              ],
            ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.heroBg,
    required this.bsRow,
    required this.form,
    required this.league,
  });

  final String heroBg;
  final Map<String, dynamic>? bsRow;
  final List<String> form;
  final String league;

  @override
  Widget build(BuildContext context) {
    final img = heroBg.isNotEmpty ? (heroBg.startsWith('http') ? heroBg : '${AppConfig.siteBase}$heroBg') : '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Stack(
        children: [
          if (img.isNotEmpty)
            SizedBox(
              height: 190,
              width: double.infinity,
              child: CachedNetworkImage(imageUrl: img, fit: BoxFit.cover),
            )
          else
            Container(height: 190, width: double.infinity, color: AppColors.nav),
          Container(
            height: 190,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.nav.withValues(alpha: 0.35), AppColors.nav.withValues(alpha: 0.92)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Yeşil · Beyaz · Timsah', style: TextStyle(color: AppColors.lime, fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(height: 6),
                const Text('Tutku burada.\nSahada yeşil.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, height: 1.1)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (bsRow != null)
                      _HeroPill(text: '${bsRow!['pos']}. sıra · ${bsRow!['pts']} puan'),
                    if (form.isNotEmpty) _FormPill(form: form),
                    _HeroPill(text: league),
                  ],
                ),
              ],
            ),
          ),
          const Positioned(right: 16, bottom: 16, child: Text('🐊', style: TextStyle(fontSize: 42))),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _FormPill extends StatelessWidget {
  const _FormPill({required this.form});
  final List<String> form;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: form.map((ch) => Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: _FormChip(ch: ch))).toList(),
      ),
    );
  }
}

class _FormChip extends StatelessWidget {
  const _FormChip({required this.ch});
  final String ch;

  Color get _color {
    switch (ch.toUpperCase()) {
      case 'G':
        return AppColors.accentDeep;
      case 'M':
        return AppColors.coral;
      default:
        return AppColors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
      child: Text(ch, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }
}

class _NextMatchCard extends StatelessWidget {
  const _NextMatchCard({required this.match});
  final Map<String, dynamic> match;

  @override
  Widget build(BuildContext context) {
    final home = match['home_team']?.toString() ?? '';
    final away = match['away_team']?.toString() ?? '';
    final isHome = match['is_home'] == true;
    final week = match['week'];
    final date = match['kickoff_date']?.toString() ?? match['kickoff_at']?.toString() ?? '';
    final time = match['kickoff_time']?.toString() ?? '';
    final venue = match['venue']?.toString() ?? '';
    final ticket = match['ticket_url']?.toString() ?? 'https://www.bursaspor.org.tr/';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.accentDeep.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${isHome ? 'İç saha' : 'Deplasman'}${week != null ? ' · $week. hafta' : ''}',
            style: const TextStyle(color: AppColors.accentDeep, fontWeight: FontWeight.w800, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _TeamCol(name: home, highlight: home.contains('Bursaspor'))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.muted)),
              ),
              Expanded(child: _TeamCol(name: away, highlight: away.contains('Bursaspor'))),
            ],
          ),
          const SizedBox(height: 12),
          if (date.isNotEmpty || time.isNotEmpty || venue.isNotEmpty)
            Text(
              [if (date.isNotEmpty) '📅 $date', if (time.isNotEmpty) '🕐 $time', if (venue.isNotEmpty) '📍 $venue'].join(' · '),
              style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openUrl('https://www.bursaspor.org.tr/'),
                  child: const Text('Resmi site'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => _openUrl(ticket),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accentDeep),
                  child: const Text('Bilet / Passolig'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamCol extends StatelessWidget {
  const _TeamCol({required this.name, required this.highlight});
  final String name;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: highlight ? AppColors.accentDeep : AppColors.bgSoft,
          child: Text(name.isNotEmpty ? name[0] : '?', style: TextStyle(fontWeight: FontWeight.w900, color: highlight ? Colors.white : AppColors.ink)),
        ),
        const SizedBox(height: 6),
        Text(name, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: highlight ? AppColors.accentDeep : AppColors.ink), maxLines: 2),
      ],
    );
  }
}

class _DeskSection extends StatelessWidget {
  const _DeskSection({required this.desk, required this.generated});
  final Map<String, dynamic> desk;
  final String generated;

  @override
  Widget build(BuildContext context) {
    final form = (desk['form'] as List? ?? []).map((e) => e.toString()).toList();
    return _Panel(
      title: 'Maç masası',
      trailing: form.isNotEmpty ? _FormPill(form: form) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((desk['standings_note']?.toString() ?? '').isNotEmpty)
            Text(desk['standings_note'].toString(), style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w800, fontSize: 13)),
          if ((desk['analysis']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(desk['analysis'].toString(), style: const TextStyle(height: 1.45)),
          ],
          if ((desk['preview']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            _NoteCard(title: 'Önizleme', body: desk['preview'].toString()),
          ],
          if ((desk['review']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            _NoteCard(title: 'Maç arkası', body: desk['review'].toString()),
          ],
          if (generated.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Son derleme: $generated', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bgSoft, borderRadius: BorderRadius.circular(AppRadii.sm)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13)),
        ],
      ),
    );
  }
}

class _VideosSection extends StatelessWidget {
  const _VideosSection({required this.videos});
  final List<Map<String, dynamic>> videos;

  @override
  Widget build(BuildContext context) {
    final featured = videos.first;
    final rest = videos.length > 1 ? videos.sublist(1) : <Map<String, dynamic>>[];

    return _Panel(
      title: 'Yeşil-beyaz video',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VideoCard(video: featured, large: true),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...rest.take(4).map((v) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _VideoCard(video: v))),
          ],
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video, this.large = false});
  final Map<String, dynamic> video;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final thumb = video['thumb']?.toString() ?? '';
    final title = video['title']?.toString() ?? 'Video';
    final channel = video['channel']?.toString() ?? '';
    final date = video['date_label']?.toString() ?? '';
    final watch = video['watch_url']?.toString() ?? '';

    return Material(
      color: AppColors.bgSoft,
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: watch.isEmpty ? null : () => _openUrl(watch),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thumb.isNotEmpty)
              Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: thumb,
                    height: large ? 190 : 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: large ? 15 : 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (channel.isNotEmpty || date.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text([channel, date].where((e) => e.isNotEmpty).join(' · '), style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsSection extends StatelessWidget {
  const _NewsSection({required this.news});
  final List<Map<String, dynamic>> news;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Öne çıkan gündem',
      child: Column(
        children: news.map((n) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _NewsCard(item: n))).toList(),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item});
  final Map<String, dynamic> item;

  String get _topicLabel {
    switch (item['topic']?.toString() ?? 'genel') {
      case 'mac':
        return 'Maç';
      case 'transfer':
        return 'Transfer';
      case 'yonetim':
        return 'Yönetim';
      default:
        return 'Gündem';
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = item['img_url']?.toString() ?? '';
    final url = item['url']?.toString() ?? '';
    final title = item['title']?.toString() ?? '';
    final blurb = item['blurb']?.toString() ?? '';
    final source = item['source']?.toString() ?? '';

    return Material(
      color: AppColors.bgSoft,
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: url.isEmpty ? null : () => _openUrl(url),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (img.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: CachedNetworkImage(
                      imageUrl: img.startsWith('http') ? img : '${AppConfig.siteBase}$img',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (img.isNotEmpty) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.coral.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                          child: Text(_topicLabel, style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w800, fontSize: 10)),
                        ),
                        if (source.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(child: Text(source, style: const TextStyle(color: AppColors.muted, fontSize: 11), overflow: TextOverflow.ellipsis)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, height: 1.25)),
                    if (blurb.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(blurb, style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35), maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                    if (url.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      const Text('Kaynağı aç →', style: TextStyle(color: AppColors.accentDeep, fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StandingsSection extends StatelessWidget {
  const _StandingsSection({required this.standings, required this.league});
  final List<Map<String, dynamic>> standings;
  final String league;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Lig puan durumu',
      trailing: Text(league, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 36,
          dataRowMinHeight: 34,
          dataRowMaxHeight: 40,
          columnSpacing: 14,
          columns: const [
            DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('Takım', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('O')),
            DataColumn(label: Text('G')),
            DataColumn(label: Text('B')),
            DataColumn(label: Text('M')),
            DataColumn(label: Text('P', style: TextStyle(fontWeight: FontWeight.w800))),
          ],
          rows: standings.map((r) {
            final isBs = (r['team']?.toString() ?? '').contains('Bursaspor');
            final style = TextStyle(fontWeight: isBs ? FontWeight.w900 : FontWeight.w500, color: isBs ? AppColors.accentDeep : AppColors.ink);
            return DataRow(
              color: isBs ? WidgetStateProperty.all(AppColors.accentDeep.withValues(alpha: 0.08)) : null,
              cells: [
                DataCell(Text('${r['pos']}', style: style)),
                DataCell(Text(r['team']?.toString() ?? '', style: style)),
                DataCell(Text('${r['p'] ?? ''}', style: style)),
                DataCell(Text('${r['w'] ?? ''}', style: style)),
                DataCell(Text('${r['d'] ?? ''}', style: style)),
                DataCell(Text('${r['l'] ?? ''}', style: style)),
                DataCell(Text('${r['pts'] ?? ''}', style: style)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FixtureSection extends StatelessWidget {
  const _FixtureSection({
    required this.upcoming,
    required this.recent,
    required this.matches,
    required this.allOpen,
    required this.onToggleAll,
  });

  final List<Map<String, dynamic>> upcoming;
  final List<Map<String, dynamic>> recent;
  final List<Map<String, dynamic>> matches;
  final bool allOpen;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Fikstür & sonuçlar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (upcoming.isNotEmpty) ...[
            const Text('Sıradaki maçlar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 8),
            ...upcoming.map((m) => _FixCard(match: m, upcoming: true)),
          ],
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Son sonuçlar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 8),
            ...recent.map((m) => _FixCard(match: m, upcoming: false)),
          ],
          if (matches.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onToggleAll, child: Text(allOpen ? 'Tüm sezonu gizle' : 'Tüm sezon fikstürü (${matches.length})')),
            if (allOpen) ...matches.map((m) => _FixRow(match: m)),
          ],
        ],
      ),
    );
  }
}

class _FixCard extends StatelessWidget {
  const _FixCard({required this.match, required this.upcoming});
  final Map<String, dynamic> match;
  final bool upcoming;

  @override
  Widget build(BuildContext context) {
    final home = match['home_team']?.toString() ?? '';
    final away = match['away_team']?.toString() ?? '';
    final week = match['week'];
    final isHome = match['is_home'] == true;
    final when = match['kickoff_at']?.toString() ?? '';
    final venue = match['venue']?.toString() ?? '';
    final ticket = match['ticket_url']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHome ? AppColors.accentDeep.withValues(alpha: 0.08) : AppColors.bgSoft,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${week != null ? '$week. hafta' : 'Maç'} · ${isHome ? 'İç saha' : 'Deplasman'}', style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (!upcoming && match['home_score'] != null)
                Text('${match['home_score']}–${match['away_score']}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 6),
          Text('$home vs $away', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          if (when.isNotEmpty || venue.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text([when, venue].where((e) => e.isNotEmpty).join(' · '), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
          if (upcoming && ticket.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () => _openUrl(ticket), child: const Text('Bilet →')),
            ),
        ],
      ),
    );
  }
}

class _FixRow extends StatelessWidget {
  const _FixRow({required this.match});
  final Map<String, dynamic> match;

  @override
  Widget build(BuildContext context) {
    final home = match['home_team']?.toString() ?? '';
    final away = match['away_team']?.toString() ?? '';
    final week = match['week'];
    final played = match['played'] == true;
    final score = played ? '${match['home_score']}–${match['away_score']}' : 'vs';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('${week ?? '—'}', style: const TextStyle(color: AppColors.muted, fontSize: 12))),
          Expanded(child: Text('$home $score $away', style: const TextStyle(fontSize: 12))),
          Text(match['kickoff_at']?.toString() ?? '—', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _OfficialLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(label: const Text('Resmi site'), onPressed: () => _openUrl('https://www.bursaspor.org.tr/')),
        ActionChip(label: const Text('Bursa haberleri'), onPressed: () => _openUrl('${AppConfig.siteBase}/haberler')),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

Future<void> _openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
