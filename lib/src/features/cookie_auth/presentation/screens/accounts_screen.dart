// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/routes_manager.dart';
import '../../../../core/utils/app_colors.dart';
import '../../data/models/platform_login_config.dart';
import '../../domain/entities/platform_cookie.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_event.dart';
import '../bloc/account_state.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          "Akun & Cookies",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocConsumer<AccountBloc, AccountState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.synced
                  ? "Login berhasil & cookies tersinkronisasi ke server!"
                  : "Login berhasil! Cookies tersimpan lokal. (Server sync gagal)"),
              backgroundColor:
                  state.synced ? AppColors.green : Colors.orange,
            ));
          }
          if (state is LoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.red,
            ));
          }
          if (state is LogoutSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Logout berhasil"),
              backgroundColor: AppColors.primaryColor,
            ));
          }
        },
        builder: (context, state) {
          final cookies = state is AccountsLoaded ? state.cookies : <PlatformCookie>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.white.withOpacity(0.5), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Login ke platform untuk download konten yang membutuhkan autentikasi. Cookies disimpan terenkripsi di perangkat dan disinkronkan ke server Cobalt.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...PlatformLoginConfig.supported.map((config) {
                final cookie = cookies
                    .where((c) => c.platform == config.platform)
                    .firstOrNull;
                return _PlatformTile(
                  config: config,
                  cookie: cookie,
                  onLogin: () async {
                    await Navigator.of(context).pushNamed(
                      Routes.webviewLogin,
                      arguments: config.platform,
                    );
                    if (context.mounted) {
                      context.read<AccountBloc>().add(LoadAccounts());
                    }
                  },
                  onLogout: () {
                    context
                        .read<AccountBloc>()
                        .add(LogoutFromPlatform(config.platform));
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _PlatformTile extends StatelessWidget {
  final PlatformLoginConfig config;
  final PlatformCookie? cookie;
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  const _PlatformTile({
    required this.config,
    required this.cookie,
    required this.onLogin,
    required this.onLogout,
  });

  bool get isLoggedIn => cookie != null && cookie!.hasCookies;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLoggedIn
              ? AppColors.green.withOpacity(0.3)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isLoggedIn
                  ? AppColors.green.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLoggedIn ? Icons.check_circle : Icons.person_outline,
              color: isLoggedIn ? AppColors.green : Colors.white54,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLoggedIn
                      ? "Logged in${cookie!.username != null ? ' (${cookie!.username})' : ''}"
                      : "Belum login",
                  style: TextStyle(
                    color: isLoggedIn
                        ? AppColors.green.withOpacity(0.8)
                        : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isLoggedIn)
            TextButton(
              onPressed: onLogout,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: const Text("Logout", style: TextStyle(fontSize: 12)),
            )
          else
            ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Text("Login", style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
