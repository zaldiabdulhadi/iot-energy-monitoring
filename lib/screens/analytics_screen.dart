import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/energy_metric.dart';
import '../models/energy_period_summary.dart';
import '../providers/energy_data_provider.dart';
import '../providers/energy_history_provider.dart';
import '../services/energy_api_client.dart';
import '../services/energy_csv_exporter.dart';
import '../services/energy_raw_csv_exporter.dart';
import '../theme/app_colors.dart';
import '../widgets/insight_card.dart';
import '../widgets/layout.dart';
import '../widgets/metric_tile.dart';
import '../widgets/section_header.dart';

/// Analisis riwayat: konsumsi per periode, rentang tiap parameter, dan
/// rekomendasi yang dihitung dari angka itu.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  EnergyMetric _chartMetric = EnergyMetric.power;
  bool _exporting = false;
  bool _exportingRaw = false;

  /// Menulis riwayat periode terpilih ke Downloads lalu membuka lembar bagikan.
  ///
  /// Tombol dikunci selama proses berjalan supaya dua sentuhan cepat tidak
  /// menghasilkan dua berkas dengan nama berbeda di folder yang sama.
  Future<void> _export(HistoryPeriod period) async {
    if (_exporting) return;
    setState(() => _exporting = true);

    final messenger = ScaffoldMessenger.of(context);
    final exporter = context.read<EnergyCsvExporter>();
    // Lembar bagikan di iPad harus punya titik jangkar, jadi koordinat layar
    // dari daftar ini ikut dikirim. Di Android parameter ini diabaikan.
    final anchor = context.findRenderObject() as RenderBox?;
    final origin = anchor == null || !anchor.hasSize
        ? null
        : (anchor.localToGlobal(Offset.zero) & anchor.size);

    try {
      final result = await exporter.export(period, origin: origin);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${result.rowCount} jam tersimpan di ${result.location}',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on EnergyExportException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Gagal menyimpan berkas. Cek ruang penyimpanan.'),
          backgroundColor: AppColors.critical,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// Menulis seluruh sampel mentah dari server collector ke Downloads lalu
  /// membuka lembar bagikan.
  ///
  /// Berbeda dari [_export] yang membaca riwayat di perangkat, ekspor ini
  /// menarik langsung dari server, jadi server harus terjangkau saat tombol
  /// ditekan dan berkasnya identik dengan `data.db` servernya.
  Future<void> _exportRaw() async {
    final messenger = ScaffoldMessenger.of(context);
    final endpoint = context.read<EnergyDataProvider>().endpoint;
    if (endpoint == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Hubungkan dulu ke server ESP di menu Koneksi API ESP, lalu '
            'coba unduh lagi.',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_exportingRaw) return;
    setState(() => _exportingRaw = true);

    final anchor = context.findRenderObject() as RenderBox?;
    final origin = anchor == null || !anchor.hasSize
        ? null
        : (anchor.localToGlobal(Offset.zero) & anchor.size);

    try {
      final result =
          await context.read<EnergyRawCsvExporter>().export(endpoint, origin: origin);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${result.rowCount} sampel tersimpan di ${result.location}',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on EnergyExportException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on EnergyApiException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan berkas. Cek ruang penyimpanan.'),
          backgroundColor: AppColors.critical,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _exportingRaw = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<EnergyHistoryProvider>();
    final gutters = Gutters.of(context);
    final summary = history.summary;

    return ListView(
      padding: gutters.all,
      children: [
        Text(
          'Analisis',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Dari riwayat per jam yang tercatat di perangkat',
          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        _PeriodSelector(
          selected: history.selectedPeriod,
          onChanged: (period) => history.select(period),
        ),
        const SizedBox(height: 16),
        if (history.error != null)
          EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Riwayat tidak terbaca',
            body: '${history.error}',
          )
        else if (summary == null || history.isEmpty)
          const EmptyState(
            icon: Icons.query_stats_rounded,
            title: 'Belum ada riwayat untuk periode ini',
            body: 'Data muncul setelah satu jam penuh tercatat. Untuk periode '
                'lebih panjang, aplikasi perlu berjalan beberapa waktu.',
          )
        else ...[
          if (summary.isDemo) ...[
            const _DemoBanner(),
            const SizedBox(height: 16),
          ],
          _SummaryCard(summary: summary, previous: history.previous),
          const SizedBox(height: 18),
          _ConsumptionChart(summary: summary),
          const SizedBox(height: 18),
          _MetricHistoryChart(
            summary: summary,
            metric: _chartMetric,
            onMetricChanged: (m) => setState(() => _chartMetric = m),
          ),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Rentang parameter',
            icon: Icons.table_rows_outlined,
          ),
          const SizedBox(height: 10),
          _ParameterTable(summary: summary),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Rekomendasi smart',
            icon: Icons.lightbulb_outline_rounded,
          ),
          const SizedBox(height: 10),
          if (summary.isDemo)
            const _DemoNote(text: 'Disusun dari data contoh, bukan pengukuran.')
          else if (history.isThin)
            const EmptyState(
              icon: Icons.hourglass_empty_rounded,
              title: 'Data masih sedikit',
              body: 'Perlu minimal dua jam terekam sebelum pola bisa dibaca. '
                  'Kembali beberapa saat lagi.',
            )
          else if (history.insights.isEmpty)
            const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'Tidak ada yang perlu dikerjakan',
              body: 'Semua parameter berada di rentang yang wajar untuk '
                  'periode ini.',
            )
          else
            InsightList(insights: history.insights),
        ],
        const SizedBox(height: 18),
        const SectionHeader(
          title: 'Unduh data',
          icon: Icons.download_rounded,
        ),
        const SizedBox(height: 10),
        _ExportCard(
          period: history.selectedPeriod,
          exporting: _exporting,
          exportingRaw: _exportingRaw,
          onExport: () => _export(history.selectedPeriod),
          onExportRaw: _exportRaw,
        ),
      ],
    );
  }
}

/// Mengunduh riwayat sebagai CSV.
///
/// Dua pilihan: riwayat per jam periode terpilih (dari `hourly_history` di
/// perangkat, jadi offline) dan sampel mentah langsung dari server collector
/// (format sama persis dengan `server/export_csv.py`).
class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.period,
    required this.exporting,
    required this.exportingRaw,
    required this.onExport,
    required this.onExportRaw,
  });

  final HistoryPeriod period;
  final bool exporting;
  final bool exportingRaw;
  final VoidCallback onExport;
  final VoidCallback onExportRaw;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Berkas CSV · ${period.label.toLowerCase()}',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Satu baris per jam: kWh, daya, tegangan, arus, frekuensi, dan '
            'cakupan rekaman. Tersimpan di folder Download/SmartEnergy, lalu '
            'dibagikan lewat lembar bagikan.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: exporting ? null : onExport,
              icon: exporting
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.ios_share_rounded, size: 18),
              label: Text(exporting ? 'Menyimpan…' : 'Unduh dan bagikan CSV'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                textStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sampel mentah dari server',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Satu baris per pengukuran ESP di server (kolom: id, waktu, '
            'tegangan, arus, daya, energi, frekuensi, pf) — format sama '
            'persis dengan `server/export_csv.py`. Butuh server terjangkau.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: exportingRaw ? null : onExportRaw,
              icon: exportingRaw
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.storage_rounded, size: 18),
              label: Text(
                exportingRaw ? 'Mengunduh…' : 'Unduh dan bagikan sampel mentah',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                textStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Peringatan bahwa seluruh angka di layar ini bukan hasil pengukuran.
///
/// Warna dan penanda asterisk pada sumbu dipilih supaya tidak bisa luput dari
/// perhatian, termasuk saat layarnya difoto atau dibaca orang lain.
class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFFFF6E0),
      borderColor: AppColors.warning,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.science_outlined,
            size: 19,
            color: Color(0xFF9A7B1A),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data contoh, bukan pengukuran',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A5F12),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Meter ini belum merekam apa pun, jadi angka di bawah '
                  'dibuat dari pola pemakaian rumah tangga dan hanya untuk '
                  'menilai tampilan. Bukan hasil bacaan ESP, jangan dipakai '
                  'acuan. Asterisk pada sumbu menandai data contoh.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.45,
                    color: Color(0xFF7A5F12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Catatan kecil penanda data contoh, untuk bagian yang tidak perlu peringatan
/// penuh karena banner di atas sudah menjelaskannya.
class _DemoNote extends StatelessWidget {
  const _DemoNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Label sumbu grafik, diberi penanda kalau angkanya data contoh.
///
/// Asterisk ikut pada label yang benar-benar terlihat, bukan cuma di tooltip,
/// supaya tangkapan layar atau grafik yang dibagikan ke orang lain tetap
/// terbaca sebagai data contoh.
String _axisLabel(HistoryBucket bucket, bool isDemo) =>
    isDemo ? '${bucket.label}*' : bucket.label;

/// Amber untuk data contoh, abu-abu untuk rekaman asli.
Color _axisLabelColor(bool isDemo) =>
    isDemo ? const Color(0xFF9A7B1A) : AppColors.textMuted;

/// Gaya label sumbu bawah, dipakai untuk merender sekaligus untuk mengukur
/// lebarnya supaya keduanya tidak pernah berbeda.
TextStyle _axisLabelStyle(bool isDemo) =>
    TextStyle(fontSize: 9, color: _axisLabelColor(isDemo));

/// Ruang yang dicadangkan untuk label sumbu kiri pada grafik garis.
const double _leftAxisReserved = 38;

/// Sisa ruang minimum antara dua label sumbu bawah.
///
/// Tanpa jarak ini label yang berdempetan tetap terlihat menempel dan jauh
/// lebih sulit dibaca daripada label yang hanya bersinggungan.
const double _axisLabelGap = 6;

/// Berapa banyak bucket yang dilewati antar label sumbu bawah.
///
/// Menghitungnya dari geometri yang benar-benar dirender fl_chart, bukan dari
/// lebar kartu. `constraints.maxWidth` itu lebih besar daripada area plot:
/// sumbu bawah memakai `reservedSize` dan tiap batang `spaceAround` menambah
/// ruang di sekitarnya. Kalau slot per bucket diperkirakan dari lebar kartu,
/// hasilnya terlalu lega dan label tetap saling menindih di layar sempit.
///
/// Yang dipakai adalah [TitleMeta.parentAxisSize], yaitu lebar area plot
/// setelah dikurangi ruang yang dipesan sumbu dan tepi. `min` dan `max` milik
/// fl_chart tidak bisa dipercaya di sini: untuk `BarChart` keduanya selalu
/// 0 dan 1 apa pun jumlah batangnya, karena posisi batang dihitung dari lebar
/// batang, bukan dari skala data. Jumlah bucket yang diketahui aplikasi jauh
/// lebih andal, dan membagi dua angka itu menghasilkan jarak piksel satu bucket
/// untuk kedua jenis grafik.
int _axisLabelStep({
  required int count,
  required double plotWidth,
  required double labelWidth,
}) {
  if (count <= 1 || plotWidth <= 0) return 1;
  final perBucket = plotWidth / count;
  final step = ((labelWidth + _axisLabelGap) / perBucket).ceil();
  return step.clamp(1, count);
}

/// Lebar label sumbu terlebar, diukur dari teks yang akan dirender.
///
/// Panjang tiap label berbeda-beda, misalnya `11.00` dan `1 Sep`, jadi lebar
/// label tidak bisa ditulis sebagai konstanta. Pengukuran memakai
/// [MediaQuery.textScalerOf] supaya pengguna yang memperbesar huruf ikut
/// terbayar: labelnya jadi lebih rapat, bukan lebih menindih.
double _widestAxisLabelWidth(
  BuildContext context,
  List<String> labels,
  TextStyle style,
) {
  final painter = TextPainter(
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
  );
  var widest = 0.0;
  for (final label in labels) {
    painter
      ..text = TextSpan(text: label, style: style)
      ..layout();
    if (painter.width > widest) widest = painter.width;
  }
  return widest;
}

/// Label sumbu bawah untuk satu bucket, atau kosong kalau bucket itu dilewati.
///
/// Kosongnya dikembalikan dari sini, bukan disaring fl_chart, karena
/// `BarChart` mengabaikan `SideTitles.interval` dan memanggil fungsi ini untuk
/// setiap batang. Tanpa penyaringan di tempat ini, 24 label "13.00" digambar
/// di atas 24 batang selebar belasan piksel dan saling menimpa.
///
/// Langkah penyaringan dihitung ulang di sini dari [TitleMeta] supaya
/// berdasarkan jarak piksel antar dua label yang benar-benar ada, bukan
/// perkiraan lebar kartu.
Widget _axisTitle({
  required int index,
  required int count,
  required List<String> labels,
  required double labelWidth,
  required TitleMeta meta,
  required TextStyle style,
}) {
  if (index < 0 || index >= labels.length) {
    return const SizedBox.shrink();
  }
  final step = _axisLabelStep(
    count: count,
    plotWidth: meta.parentAxisSize,
    labelWidth: labelWidth,
  );
  if (index % step != 0) {
    return const SizedBox.shrink();
  }
  return SideTitleWidget(
    meta: meta,
    child: Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(labels[index], style: style),
    ),
  );
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final HistoryPeriod selected;
  final ValueChanged<HistoryPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final period in HistoryPeriod.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(period),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                  decoration: BoxDecoration(
                    color: period == selected
                        ? AppColors.primaryDark
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      period.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: period == selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
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

/// Total konsumsi, daya, dan perbandingan dengan periode sebelumnya.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.previous});

  final EnergyPeriodSummary summary;
  final EnergyPeriodSummary? previous;

  @override
  Widget build(BuildContext context) {
    final change = summary.changePct(previous);

    return AppCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE8F6EB), Color(0xFFF8FAF9)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total ${summary.period.label.toLowerCase()} · '
                  '${summary.period.description}',
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (change != null) ...[
                const SizedBox(width: 8),
                Flexible(child: TrendBadge(percent: change)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          AdaptiveNumber(
            value: formatValue(summary.totalKwh, 2),
            suffix: 'kWh',
            fontSize: 32,
            color: AppColors.deepGreen,
          ),
          const SizedBox(height: 4),
          Text(
            change == null
                ? 'Belum ada periode sebelumnya untuk dibandingkan'
                : 'dibanding ${formatValue(previous!.totalKwh, 2)} kWh '
                    'periode sebelumnya',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          MetricGrid(
            tiles: [
              SummaryTile(
                label: 'Daya puncak',
                value: formatValue(summary.peakPowerW, 1),
                suffix: 'W',
                icon: Icons.bolt_rounded,
                caption: summary.peakHour == null
                    ? 'belum ada'
                    : 'pukul ${_hour(summary.peakHour!)}',
              ),
              SummaryTile(
                label: 'Rata-rata daya',
                value: formatValue(summary.averagePowerW, 1),
                suffix: 'W',
                icon: Icons.bolt_rounded,
                caption: 'seluruh periode',
              ),
              SummaryTile(
                label: 'Jejak karbon',
                value: formatValue(summary.co2Kg, 1),
                suffix: 'kg',
                icon: Icons.eco_outlined,
                caption: 'faktor grid',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CoverageRow(summary: summary),
        ],
      ),
    );
  }

  /// Label jam untuk keterangan daya puncak.
  static String _hour(DateTime hour) =>
      '${hour.hour.toString().padLeft(2, '0')}.${hour.minute.toString().padLeft(2, '0')}';
}

/// Kelengkapan data, karena angka lain di kartu ini bergantung padanya.
class _CoverageRow extends StatelessWidget {
  const _CoverageRow({required this.summary});

  final EnergyPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    // Untuk data contoh, hitungan jam yang "terekam" cuma menggambarkan berapa
    // banyak titik rekaan yang dibuat. Menampilkannya sebagai achievement
    // pengukuran akan menipu, jadi bar disembunyikan dan diganti keterangan.
    if (summary.isDemo) {
      return const Text(
        'Cakupan di atas berasal dari data contoh, bukan kelengkapan '
        'pengukuran meter.',
        style: TextStyle(
          fontSize: 10.5,
          height: 1.4,
          color: AppColors.textMuted,
        ),
      );
    }

    // Berapa jam benar-benar terekam dibanding jam yang diharapkan periode ini.
    final expected = summary.expectedHours;
    final ratio = expected <= 0 ? 0.0 : summary.observedHours / expected;
    final pct = (ratio * 100).clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${summary.observedHours} dari ${summary.expectedHours} jam '
                'terekam',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 6,
            backgroundColor: AppColors.primaryLight,
            color: pct >= 90 ? AppColors.primaryDark : AppColors.warning,
          ),
        ),
      ],
    );
  }
}

/// Konsumsi per bucket: per jam, per hari, atau per bulan sesuai periode.
class _ConsumptionChart extends StatelessWidget {
  const _ConsumptionChart({required this.summary});

  final EnergyPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final buckets = summary.buckets;
    final filled = buckets.where((b) => !b.isEmpty).toList();
    if (filled.length < 2) {
      return const AppCard(
        padding: EdgeInsets.symmetric(vertical: 22, horizontal: 18),
        child: Text(
          'Butuh minimal dua titik data untuk menggambar grafik.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
      );
    }

    // Konsumsi per jam (periode harian) ditampilkan dalam watt-hour supaya
    // angkanya tidak selalu "0,xxx" di depan koma; bucket per hari/bulan tetap
    // kilowatt-hour.
    final perHour = summary.period == HistoryPeriod.day;
    double toEnergy(double kwh) => perHour ? kwh * 1000 : kwh;
    final String unit = perHour ? 'Wh' : 'kWh';
    final int decimals = perHour ? 0 : 2;

    final maxY = _niceMax(
      filled.map((b) => toEnergy(b.kwh)).reduce((a, b) => a > b ? a : b),
    );
    final peak = filled.reduce((a, b) => b.kwh > a.kwh ? b : a);
    final labelStyle = _axisLabelStyle(summary.isDemo);
    final axisLabels = [
      for (final bucket in buckets) _axisLabel(bucket, summary.isDemo),
    ];
    final widestLabel = _widestAxisLabelWidth(context, axisLabels, labelStyle);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Konsumsi ${_unitOf(summary.period)}',
            action: 'puncak ${formatValue(toEnergy(peak.kwh), decimals)} $unit',
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barGroups: [
                      for (var i = 0; i < buckets.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              // Harus ikut satuan toEnergy, sama seperti maxY
                              // di atas. Kalau lewat kWh langsung, batang
                              // periode "Hari" tergambar seribu kali pendek.
                              toY: toEnergy(buckets[i].kwh),
                              width: _barWidth(buckets.length),
                              color: buckets[i].isEmpty
                                  ? AppColors.border
                                  : buckets[i] == peak
                                      ? AppColors.cyanAccent
                                      : AppColors.primary,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ],
                        ),
                    ],
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppColors.border.withValues(alpha: 0.6),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
                          // Sengaja 1: penyaringan label harus memakai
                          // geometri plot yang baru diketahui saat render, dan
                          // itu diurus [_axisTitle]. Jumlah bucket kecil, jadi
                          // membangun widget untuk tiap batang lalu membuangnya
                          // bukan biaya yang berarti.
                          interval: 1,
                          getTitlesWidget: (value, meta) => _axisTitle(
                            index: value.toInt(),
                            count: buckets.length,
                            labels: axisLabels,
                            labelWidth: widestLabel,
                            meta: meta,
                            style: labelStyle,
                          ),
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.deepGreen,
                        getTooltipItem: (group, _, rod, _) {
                          final bucket = buckets[group.x];
                          return BarTooltipItem(
                            '${bucket.label}\n'
                            '${formatValue(toEnergy(rod.toY), decimals)} $unit',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  static String _unitOf(HistoryPeriod period) => switch (period) {
        HistoryPeriod.day => 'per jam',
        HistoryPeriod.week || HistoryPeriod.month => 'per hari',
        HistoryPeriod.year => 'per bulan',
      };

  /// Lebar batang mengecil seiring bertambahnya jumlah bucket.
  static double _barWidth(int count) {
    if (count <= 8) return 16;
    if (count <= 16) return 9;
    if (count <= 26) return 6;
    return 4;
  }

  static double _niceMax(double value) {
    if (value <= 0) return 1;
    final step = value > 20 ? 5.0 : (value > 5 ? 1.0 : 0.5);
    return (value / step).ceil() * step;
  }
}

/// Garis rata-rata satu parameter sepanjang periode.
class _MetricHistoryChart extends StatelessWidget {
  const _MetricHistoryChart({
    required this.summary,
    required this.metric,
    required this.onMetricChanged,
  });

  final EnergyPeriodSummary summary;
  final EnergyMetric metric;
  final ValueChanged<EnergyMetric> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    final filled = summary.buckets.where((b) => !b.isEmpty).toList();
    if (filled.length < 2) return const SizedBox.shrink();

    final values = [for (final b in filled) b.metricOf(metric) ?? 0];
    final average = summary.averageOf(metric) ?? 0;
    final maxY = _niceMax(values.reduce((a, b) => a > b ? a : b));
    final labelStyle = _axisLabelStyle(summary.isDemo);
    final axisLabels = [
      for (final bucket in filled) _axisLabel(bucket, summary.isDemo),
    ];
    final widestLabel = _widestAxisLabelWidth(context, axisLabels, labelStyle);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Sejarah parameter',
            icon: Icons.show_chart_rounded,
          ),
          const SizedBox(height: 12),
          _MetricChips(
            selected: metric,
            onChanged: onMetricChanged,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (filled.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY,
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppColors.border.withValues(alpha: 0.6),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: average.clamp(0, maxY),
                          color: AppColors.cyanAccent,
                          strokeWidth: 1.4,
                          dashArray: [6, 4],
                        ),
                      ],
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
                          // Sama seperti grafik batang: penyaringan label
                          // ditentukan [_axisTitle] dari geometri saat render.
                          interval: 1,
                          getTitlesWidget: (value, meta) => _axisTitle(
                            index: value.toInt(),
                            count: filled.length,
                            labels: axisLabels,
                            labelWidth: widestLabel,
                            meta: meta,
                            style: labelStyle,
                          ),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: _leftAxisReserved,
                          getTitlesWidget: (value, meta) => SideTitleWidget(
                            meta: meta,
                            child: Text(
                              formatValue(value, value >= 10 ? 0 : 1),
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => AppColors.deepGreen,
                        getTooltipItems: (spots) => [
                          for (final spot in spots)
                            LineTooltipItem(
                              '${formatValue(spot.y, metric.decimals)} ${metric.unit}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < filled.length; i++)
                            FlSpot(i.toDouble(), values[i]),
                        ],
                        isCurved: true,
                        curveSmoothness: 0.3,
                        barWidth: 2.5,
                        color: AppColors.primaryDark,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.35),
                              AppColors.primary.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 14,
                height: 2,
                color: AppColors.cyanAccent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'rata-rata ${formatValue(average, metric.decimals)} '
                  '${metric.unit}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static double _niceMax(double value) {
    if (value <= 0) return 1;
    final step = value > 20 ? 5.0 : (value > 5 ? 1.0 : 0.5);
    return (value / step).ceil() * step;
  }
}

/// Pemilih parameter untuk grafik sejarah.
class _MetricChips extends StatelessWidget {
  const _MetricChips({required this.selected, required this.onChanged});

  final EnergyMetric selected;
  final ValueChanged<EnergyMetric> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: EnergyMetric.tracked.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final metric = EnergyMetric.tracked[index];
          final isSelected = metric == selected;
          return GestureDetector(
            onTap: () => onChanged(metric),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryDark : AppColors.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? AppColors.primaryDark : AppColors.border,
                ),
              ),
              child: Text(
                metric.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Tabel rata-rata, minimum, dan maksimum tiap parameter dalam periode.
class _ParameterTable extends StatelessWidget {
  const _ParameterTable({required this.summary});

  final EnergyPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                flex: 4,
                child: Text(
                  'Parameter',
                  style: _headerStyle,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Rata-rata',
                  textAlign: TextAlign.right,
                  style: _headerStyle,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Rentang',
                  textAlign: TextAlign.right,
                  style: _headerStyle,
                ),
              ),
              const Expanded(
                flex: 2,
                child: SizedBox.shrink(),
              ),
            ],
          ),
          const Divider(height: 18, color: AppColors.border),
          for (final metric in EnergyMetric.tracked) ...[
            _ParameterRow(metric: metric, summary: summary),
            if (metric != EnergyMetric.tracked.last)
              const Divider(height: 14, color: AppColors.border),
          ],
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );
}

class _ParameterRow extends StatelessWidget {
  const _ParameterRow({required this.metric, required this.summary});

  final EnergyMetric metric;
  final EnergyPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final average = summary.averageOf(metric);
    final min = summary.minimums[metric];
    final max = summary.maximums[metric];
    final status = average == null
        ? MetricStatus.healthy
        : metric.classify(average);
    final tone = switch (status) {
      MetricStatus.healthy => AppColors.textPrimary,
      MetricStatus.warning => AppColors.warning,
      MetricStatus.critical => AppColors.critical,
    };

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Icon(metric.icon, size: 15, color: AppColors.primaryDark),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            average == null
                ? '-'
                : '${formatValue(average, metric.decimals)} ${metric.unit}',
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: tone,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            _rangeLabel(min, max),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: metric.isBounded
                ? Icon(
                    status == MetricStatus.healthy
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    size: 15,
                    color: status == MetricStatus.healthy
                        ? AppColors.success
                        : tone,
                  )
                : const Icon(Icons.remove_rounded, size: 15, color: AppColors.border),
          ),
        ),
      ],
    );
  }

  /// Rentang hanya ditampilkan kalau kedua ujungnya ada.
  ///
  /// Arus hanya punya maksimum dan faktor daya hanya punya minimum, jadi
  /// menampilkan "0,00" sebagai ujung yang tidak pernah diukur akan mengarang
  /// angka.
  static String _rangeLabel(double? min, double? max) {
    if (min != null && max != null) {
      return '${min.toStringAsFixed(1)}-${max.toStringAsFixed(1)}';
    }
    if (max != null) return '<= ${max.toStringAsFixed(1)}';
    if (min != null) return '>= ${min.toStringAsFixed(1)}';
    return '-';
  }
}
