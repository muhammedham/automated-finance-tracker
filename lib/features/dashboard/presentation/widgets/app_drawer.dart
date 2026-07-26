import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// A real sliding nav drawer — this is a plain Flutter `Drawer` handed to
/// `Scaffold.drawer`, so edge-swipe-to-open and the dimmed scrim behind it
/// come for free from the framework, exactly like YouTube's. Styled with a
/// compact identity header up top and a plain destination list below, each
/// row using the same soft plum icon-chip look as the rest of the app
/// instead of stock Material ListTiles.
class AppDrawer extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onCategories;
  final VoidCallback onSync;
  final VoidCallback onLimit;

  const AppDrawer({
    super.key,
    required this.onAdd,
    required this.onCategories,
    required this.onSync,
    required this.onLimit,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.black,
      width: 300,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppGradients.chipSelected,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.mauveDim(0.35), blurRadius: 14, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.black, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MyWallet', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text('Personal finance', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.offWhiteDim(0.08), height: 1),
            const SizedBox(height: 10),
            _DrawerTile(
              icon: Icons.add_rounded,
              label: 'Add transaction',
              onTap: () {
                Navigator.pop(context);
                onAdd();
              },
            ),
            _DrawerTile(
              icon: Icons.category_outlined,
              label: 'Manage categories',
              onTap: () {
                Navigator.pop(context);
                onCategories();
              },
            ),
            _DrawerTile(
              icon: Icons.sync_rounded,
              label: 'Sync bank emails',
              onTap: () {
                Navigator.pop(context);
                onSync();
              },
            ),
            _DrawerTile(
              icon: Icons.tune_rounded,
              label: 'Daily limit',
              onTap: () {
                Navigator.pop(context);
                onLimit();
              },
            ),
            const Spacer(),
            Divider(color: AppColors.offWhiteDim(0.08), height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'MyWallet v1.0',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11.5,
                  color: AppColors.offWhiteDim(0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerTile({required this.icon, required this.label, required this.onTap});

  @override
  State<_DrawerTile> createState() => _DrawerTileState();
}

class _DrawerTileState extends State<_DrawerTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        onHighlightChanged: (v) => setState(() => _pressed = v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _pressed ? AppColors.plumElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.plumElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.offWhiteDim(0.06)),
                ),
                child: Icon(widget.icon, size: 18, color: AppColors.offWhiteDim(0.85)),
              ),
              const SizedBox(width: 14),
              Text(widget.label, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
