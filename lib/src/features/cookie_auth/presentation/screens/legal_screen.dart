import 'package:flutter/material.dart';

import '../../../../core/utils/app_colors.dart';

/// Privacy Policy + Terms of Service, shown from the Accounts screen.
class LegalScreen extends StatelessWidget {
  /// initialTab: 0 = Privacy Policy, 1 = Terms of Service
  final int initialTab;
  const LegalScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = theme.textTheme.bodyMedium?.color ?? Colors.white;

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.cardColor,
          iconTheme: IconThemeData(color: fgColor),
          title: Text(
            "Kebijakan & Ketentuan",
            style: TextStyle(color: fgColor, fontSize: 18),
          ),
          bottom: TabBar(
            labelColor: AppColors.primaryColor,
            unselectedLabelColor:
                isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
            indicatorColor: AppColors.primaryColor,
            tabs: const [
              Tab(text: "Privasi"),
              Tab(text: "Ketentuan"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LegalBody(sections: _privacySections),
            _LegalBody(sections: _termsSections),
          ],
        ),
      ),
    );
  }
}

class _Section {
  final String title;
  final String body;
  const _Section(this.title, this.body);
}

class _LegalBody extends StatelessWidget {
  final List<_Section> sections;
  const _LegalBody({required this.sections});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final mutedColor =
        isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight;

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: sections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (_, i) {
        final s = sections[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.title,
              style: TextStyle(
                color: fgColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.body,
              style: TextStyle(color: mutedColor, fontSize: 13, height: 1.5),
            ),
          ],
        );
      },
    );
  }
}

const List<_Section> _privacySections = [
  _Section(
    "Ringkasan",
    "EL-Saver adalah aplikasi untuk mengunduh video/audio dari platform media sosial "
        "untuk penggunaan pribadi. Kami menghargai privasi Anda dan meminimalkan data "
        "yang kami proses. Aplikasi ini tidak menjual data pribadi Anda.",
  ),
  _Section(
    "Data yang Diproses",
    "• Tautan (URL) yang Anda tempel: diproses untuk mengambil media, tidak disimpan permanen.\n"
        "• Cookies login (opsional): jika Anda login ke sebuah platform lewat fitur Akun & Cookies, "
        "cookies tersebut disimpan TERENKRIPSI di perangkat Anda dan disinkronkan ke server unduhan "
        "milik kami semata-mata untuk mengakses konten yang memerlukan autentikasi.\n"
        "• File hasil unduhan: disimpan di penyimpanan/galeri perangkat Anda sendiri.",
  ),
  _Section(
    "Cookies & Login Platform",
    "Fitur Akun & Cookies memungkinkan Anda login ke YouTube (& YouTube Music), Instagram (& Threads), "
        "Facebook, Twitter/X, TikTok, dan Bilibili. Cookies hanya digunakan untuk mengunduh konten "
        "yang membutuhkan sesi login. Anda dapat logout kapan saja untuk menghapus cookies dari "
        "perangkat dan server.",
  ),
  _Section(
    "Iklan & Analitik",
    "Aplikasi menampilkan iklan (Google AdMob) untuk mendukung pengembangan. AdMob dapat memproses "
        "pengenal perangkat sesuai kebijakan Google. Kami tidak menambahkan pelacak pihak ketiga lain.",
  ),
  _Section(
    "Penyimpanan & Izin",
    "Aplikasi meminta izin penyimpanan untuk menyimpan file unduhan ke galeri, dan izin install "
        "aplikasi untuk pembaruan otomatis. Izin hanya digunakan sesuai fungsinya.",
  ),
  _Section(
    "Hak Anda",
    "Anda dapat menghapus data lokal kapan saja dengan logout, menghapus riwayat unduhan, atau "
        "menghapus (uninstall) aplikasi. Untuk pertanyaan privasi, hubungi pengembang.",
  ),
];

const List<_Section> _termsSections = [
  _Section(
    "Penerimaan Ketentuan",
    "Dengan menggunakan EL-Saver, Anda menyetujui ketentuan ini. Jika tidak setuju, "
        "mohon berhenti menggunakan aplikasi.",
  ),
  _Section(
    "Penggunaan yang Diizinkan",
    "EL-Saver ditujukan untuk mengunduh konten guna penggunaan pribadi, offline, dan sah. "
        "Anda bertanggung jawab memastikan bahwa Anda memiliki hak atau izin untuk mengunduh "
        "konten tertentu.",
  ),
  _Section(
    "Hak Cipta & Konten Pihak Ketiga",
    "Konten dari YouTube, Instagram, Threads, Twitter/X, Facebook, TikTok, Bilibili, dan platform "
        "lain adalah milik pemilik hak cipta masing-masing. Anda dilarang menggunakan konten "
        "hasil unduhan untuk distribusi ulang, komersial, atau pelanggaran hak cipta. "
        "EL-Saver tidak berafiliasi dengan platform-platform tersebut.",
  ),
  _Section(
    "Tanpa Jaminan",
    "Aplikasi disediakan \"sebagaimana adanya\". Ketersediaan unduhan bergantung pada platform "
        "sumber yang dapat berubah sewaktu-waktu, sehingga sebagian fitur mungkin tidak selalu "
        "berfungsi. Kami tidak menjamin kelancaran tanpa gangguan.",
  ),
  _Section(
    "Batasan Tanggung Jawab",
    "Pengembang tidak bertanggung jawab atas penyalahgunaan aplikasi, pelanggaran hak cipta oleh "
        "pengguna, atau kerugian yang timbul dari penggunaan aplikasi.",
  ),
  _Section(
    "Perubahan Ketentuan",
    "Ketentuan ini dapat diperbarui sewaktu-waktu. Penggunaan berkelanjutan setelah pembaruan "
        "berarti Anda menerima ketentuan yang baru.",
  ),
];
