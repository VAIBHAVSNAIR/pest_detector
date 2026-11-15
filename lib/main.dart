import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const PestGuardApp());
}

class AppColors {
  static const forest = Color(0xFF153D2B);
  static const green = Color(0xFF2E8B57);
  static const mint = Color(0xFFE7F3EB);
  static const cream = Color(0xFFF6F8F4);
  static const ink = Color(0xFF18231D);
  static const muted = Color(0xFF77837B);
  static const line = Color(0xFFE7ECE7);
  static const amber = Color(0xFFF0A83A);
  static const red = Color(0xFFD95D52);
  static const blue = Color(0xFF4F7CAC);
}

class PestGuardApp extends StatelessWidget {
  const PestGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PestGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.green,
          primary: AppColors.forest,
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
        navigationBarTheme: NavigationBarThemeData(
          height: 72,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            );
          }),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.forest,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.ink,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isPreparing = false;
  String _scanMessage = 'Choose a crop image to prepare a scan.';
  final List<ScanRecord> _history = [];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1800,
      );
      if (image == null || !mounted) return;
      setState(() {
        _selectedImage = image;
        _scanMessage =
            'Image selected. AI identification is not available yet.';
        _selectedIndex = 1;
      });
    } on Exception catch (error) {
      debugPrint('Image selection failed: $error');
      if (!mounted) return;
      _showMessage('Could not open image picker. Check app permissions.');
    }
  }

  Future<void> _prepareScan() async {
    final image = _selectedImage;
    if (image == null) {
      _showMessage('Select an image first.');
      return;
    }
    setState(() {
      _isPreparing = true;
      _scanMessage = 'Checking the selected image...';
    });
    try {
      final imageSize = await image.length();
      if (!mounted) return;
      if (imageSize == 0) {
        setState(() {
          _isPreparing = false;
          _scanMessage =
              'This image is empty. Choose another photo to continue.';
        });
        _showMessage('The selected image is empty. Please choose another.');
        return;
      }
      setState(() {
        _isPreparing = false;
        _scanMessage =
            'Image is ready. AI analysis will be available when a model is connected.';
      });
      _showMessage(
        'Image checked and ready. AI analysis is not connected yet.',
      );
    } on Exception catch (error) {
      debugPrint('Image preparation failed: $error');
      if (!mounted) return;
      setState(() {
        _isPreparing = false;
        _scanMessage = 'The image could not be read. Please choose it again.';
      });
      _showMessage(
        'Could not read the selected image. Please choose it again.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _scanMessage = 'Choose a crop image to prepare a scan.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        onStartScan: () => setState(() => _selectedIndex = 1),
        onOpenHistory: () => setState(() => _selectedIndex = 2),
        scanCount: _history.length,
        hasImage: _selectedImage != null,
      ),
      ScanPage(
        image: _selectedImage,
        isPreparing: _isPreparing,
        message: _scanMessage,
        onGallery: () => _pickImage(ImageSource.gallery),
        onCamera: () => _pickImage(ImageSource.camera),
        onPrepare: _prepareScan,
        onClear: _clearImage,
      ),
      HistoryPage(records: _history),
      const SettingsPage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.mint,
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.center_focus_strong_rounded),
            selectedIcon: Icon(Icons.center_focus_strong_rounded),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.onStartScan,
    required this.onOpenHistory,
    required this.scanCount,
    required this.hasImage,
  });

  final VoidCallback onStartScan;
  final VoidCallback onOpenHistory;
  final int scanCount;
  final bool hasImage;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const _TopBar(),
              const SizedBox(height: 24),
              const _WelcomeHeader(),
              const SizedBox(height: 22),
              _HeroCard(onTap: onStartScan),
              const SizedBox(height: 22),
              const _SectionHeading(
                title: 'Your overview',
                subtitle: 'A quick look at your protection workspace',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.document_scanner_outlined,
                      title: 'Scans',
                      value: '$scanCount',
                      caption: 'Completed analyses',
                      color: AppColors.green,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      icon: hasImage
                          ? Icons.image_outlined
                          : Icons.add_photo_alternate_outlined,
                      title: 'Crop status',
                      value: hasImage ? 'Image ready' : 'Add an image',
                      caption: hasImage
                          ? 'Ready for review'
                          : 'Start with a photo',
                      color: AppColors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _SectionHeading(
                title: 'Quick actions',
                subtitle: 'Start with one simple step',
                trailing: TextButton(
                  onPressed: onOpenHistory,
                  child: const Text('View history'),
                ),
              ),
              const SizedBox(height: 10),
              _QuickActionTile(
                icon: Icons.add_a_photo_outlined,
                title: 'Scan a crop image',
                subtitle: 'Choose a photo from your device',
                onTap: onStartScan,
              ),
              const SizedBox(height: 10),
              const _InfoBanner(),
              const SizedBox(height: 22),
              const _SectionHeading(
                title: 'How PestGuard works',
                subtitle: 'A simple workflow for crop monitoring',
              ),
              const SizedBox(height: 12),
              const _StepTile(
                number: '01',
                title: 'Capture or upload',
                description: 'Add a clear photo of the crop or insect.',
                icon: Icons.add_photo_alternate_outlined,
              ),
              const _StepTile(
                number: '02',
                title: 'AI analysis',
                description: 'A connected model can inspect the image.',
                icon: Icons.auto_awesome_outlined,
              ),
              const _StepTile(
                number: '03',
                title: 'Review guidance',
                description: 'Read the result and crop-risk information.',
                icon: Icons.assignment_turned_in_outlined,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PESTGUARD',
              style: TextStyle(
                fontSize: 15,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w900,
                color: AppColors.forest,
              ),
            ),
            Text(
              'SMART CROP PROTECTION',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.1,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5E4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: AppColors.amber),
              SizedBox(width: 6),
              Text(
                'AI offline',
                style: TextStyle(
                  color: AppColors.forest,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good day, Farmer',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: -0.7,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Keep an eye on your crops, one scan at a time.',
          style: TextStyle(color: AppColors.muted, fontSize: 14),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.forest, Color(0xFF286447)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -12,
            child: Icon(
              Icons.spa_rounded,
              size: 135,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'CROP CARE • AI ASSISTED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'A healthier field\nstarts with awareness.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Prepare a crop image for pest analysis.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.center_focus_strong_rounded, size: 18),
                label: const Text('Prepare an image'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.forest,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 13),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 15),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E4),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFF6E5C5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFB77A1B)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI analysis is not connected yet. Image selection and the app interface are ready; model integration will be added separately.',
              style: TextStyle(
                color: Color(0xFF79551E),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String number;
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.forest, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number  $title',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScanPage extends StatelessWidget {
  const ScanPage({
    super.key,
    required this.image,
    required this.isPreparing,
    required this.message,
    required this.onGallery,
    required this.onCamera,
    required this.onPrepare,
    required this.onClear,
  });

  final XFile? image;
  final bool isPreparing;
  final String message;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onPrepare;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const _PageHeader(
                eyebrow: 'IMAGE WORKSPACE',
                title: 'Crop scanner',
                subtitle: 'Add a clear image to prepare your pest scan.',
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Image preview',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (image != null)
                          TextButton.icon(
                            onPressed: onClear,
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Remove'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ImagePreview(image: image),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onGallery,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Gallery'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onCamera,
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Camera'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isPreparing ? null : onPrepare,
                        icon: isPreparing
                            ? const SizedBox(
                                height: 17,
                                width: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded),
                        label: Text(
                          isPreparing ? 'Checking image...' : 'Check image',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.forest,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _StatusCard(message: message),
              const SizedBox(height: 16),
              const _GuidanceCard(),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.image});

  final XFile? image;

  @override
  Widget build(BuildContext context) {
    if (image == null) {
      return Container(
        height: 245,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F5F0),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: const Color(0xFFDCE8DE),
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: AppColors.green,
            ),
            SizedBox(height: 12),
            Text(
              'No image selected',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Choose a photo from gallery or camera',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: SizedBox(
        height: 270,
        width: double.infinity,
        child: kIsWeb
            ? Image.network(
                image!.path,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _ImageLoadError(),
              )
            : Image.file(
                File(image!.path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _ImageLoadError(),
              ),
      ),
    );
  }
}

class _ImageLoadError extends StatelessWidget {
  const _ImageLoadError();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.mint,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: AppColors.forest, size: 36),
          SizedBox(height: 8),
          Text(
            'This image could not be displayed.',
            style: TextStyle(color: AppColors.forest),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E4),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scan preparation',
                  style: TextStyle(
                    color: AppColors.forest,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF79551E),
                    fontSize: 12,
                    height: 1.4,
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

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.line),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tips for a useful image',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          _TipRow(text: 'Keep the insect or affected leaf in focus.'),
          _TipRow(text: 'Use natural light where possible.'),
          _TipRow(text: 'Avoid motion blur and very distant subjects.'),
          _TipRow(text: 'Include enough detail around the pest.'),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.green),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.records});

  final List<ScanRecord> records;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const _PageHeader(
                eyebrow: 'YOUR ACTIVITY',
                title: 'Scan history',
                subtitle: 'Review your previous pest analysis sessions.',
              ),
              const SizedBox(height: 22),
              if (records.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 42,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 48,
                        color: AppColors.green,
                      ),
                      SizedBox(height: 13),
                      Text(
                        'No scans yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Your completed AI analyses will appear here after the model is connected.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...records.map((record) => _HistoryTile(record: record)),
            ]),
          ),
        ),
      ],
    );
  }
}

class ScanRecord {
  const ScanRecord({
    required this.title,
    required this.date,
    required this.status,
  });

  final String title;
  final DateTime date;
  final String status;
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record});

  final ScanRecord record;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: AppColors.line),
      ),
      leading: const CircleAvatar(
        backgroundColor: AppColors.mint,
        child: Icon(Icons.image_search, color: AppColors.forest),
      ),
      title: Text(
        record.title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(record.status),
      trailing: Text(
        MaterialLocalizations.of(context).formatMediumDate(record.date),
        style: const TextStyle(color: AppColors.muted, fontSize: 11),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const _PageHeader(
                eyebrow: 'PREFERENCES',
                title: 'Settings',
                subtitle: 'Application information and project status.',
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.eco, color: AppColors.forest, size: 28),
                    ),
                    SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PestGuard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'AI Pest Detection System',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text('v1.0', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _SettingsTile(
                icon: Icons.memory_outlined,
                title: 'Hardware integration',
                subtitle: 'NodeMCU connection planned',
                trailingText: 'Pending',
              ),
              const _SettingsTile(
                icon: Icons.cloud_outlined,
                title: 'AI model connection',
                subtitle: 'Roboflow backend integration',
                trailingText: 'Pending',
              ),
              const _SettingsTile(
                icon: Icons.photo_library_outlined,
                title: 'Image access',
                subtitle: 'Gallery and camera selection',
                trailingText: 'Available',
              ),
              const SizedBox(height: 18),
              const _InfoBanner(),
              const SizedBox(height: 22),
              const Center(
                child: Text(
                  'Designed to support smarter crop monitoring.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailingText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailingText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.forest, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            trailingText,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: AppColors.green,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}
