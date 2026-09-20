import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/web_theme.dart';

class WebHeader extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback? onSearchTap;

  const WebHeader({
    super.key,
    required this.activeIndex,
    required this.onSelectTab,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: WebTheme.surface,
        border: Border(
          bottom: BorderSide(color: WebTheme.border, width: 1),
        ),
        boxShadow: WebTheme.headerShadow,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: ResponsiveBreakpoints.maxContentWidth),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              // Logo & Brand
              InkWell(
                onTap: () => onSelectTab(0),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/image/logoooo.png',
                        height: 38,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.storefront,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                'UNESA',
                                style: WebTheme.navLink.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: WebTheme.accent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Marketplace',
                                style: WebTheme.navLink.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: WebTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Jual Beli Sesama Kampus',
                            style: WebTheme.navLink.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: WebTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 32),

              // Navigation Links
              Expanded(
                child: Row(
                  children: [
                    _buildNavItem(
                      index: 0,
                      label: 'Jelajah',
                      icon: Icons.explore_outlined,
                      activeIcon: Icons.explore,
                    ),
                    const SizedBox(width: 8),
                    _buildNavItem(
                      index: 1,
                      label: 'Jual Barang',
                      icon: Icons.add_circle_outline,
                      activeIcon: Icons.add_circle,
                      isSpecial: true,
                    ),
                    const SizedBox(width: 8),
                    _buildNavItem(
                      index: 2,
                      label: 'Barang Saya',
                      icon: Icons.storefront_outlined,
                      activeIcon: Icons.storefront,
                    ),
                    const SizedBox(width: 8),
                    _buildNavItem(
                      index: 3,
                      label: 'Tersimpan',
                      icon: Icons.favorite_border,
                      activeIcon: Icons.favorite,
                    ),
                    const SizedBox(width: 8),
                    _buildNavItem(
                      index: 4,
                      label: 'Pesan',
                      icon: Icons.chat_bubble_outline,
                      activeIcon: Icons.chat_bubble,
                    ),
                  ],
                ),
              ),

              // Profile & Account Actions
              _buildUserMenu(context, user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    bool isSpecial = false,
  }) {
    final isActive = activeIndex == index;

    if (isSpecial) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onSelectTab(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? WebTheme.accent : WebTheme.accent.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? WebTheme.accent : WebTheme.accent.withAlpha(80),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 16,
                  color: isActive ? Colors.white : WebTheme.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: WebTheme.navLink.copyWith(
                    color: isActive ? Colors.white : WebTheme.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onSelectTab(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? WebTheme.surfaceHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(color: WebTheme.border, width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 17,
                color: isActive ? WebTheme.accent : WebTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: WebTheme.navLink.copyWith(
                  color: isActive ? WebTheme.accent : WebTheme.textSecondary,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context, User? user) {
    return PopupMenuButton<String>(
      tooltip: 'Menu Akun',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: WebTheme.border),
      ),
      elevation: 4,
      onSelected: (value) async {
        if (value == 'profile') {
          onSelectTab(5); // Profile tab index
        } else if (value == 'logout') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Keluar Akun', style: WebTheme.sectionTitle.copyWith(fontSize: 18)),
              content: const Text('Apakah Anda yakin ingin keluar dari akun UNESA Marketplace?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WebTheme.error,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Keluar'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await Supabase.instance.client.auth.signOut();
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person_outline, size: 18, color: WebTheme.textPrimary),
              const SizedBox(width: 10),
              Text('Profil Saya', style: WebTheme.navLink),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 18, color: WebTheme.error),
              const SizedBox(width: 10),
              Text('Keluar', style: WebTheme.navLink.copyWith(color: WebTheme.error)),
            ],
          ),
        ),
      ],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: activeIndex == 5 ? WebTheme.surfaceHover : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: WebTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: WebTheme.primary,
                child: const Icon(Icons.person, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                user?.email?.split('@').first ?? 'Akun Saya',
                style: WebTheme.navLink.copyWith(fontSize: 13),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: WebTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
