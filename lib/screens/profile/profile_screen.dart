import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../services/profile_image_service.dart';
import '../../widgets/dialogs/image_position_picker.dart';
import '../onboarding/onboarding_flow_screen.dart';

/// Profile Screen - Thông tin cá nhân
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileImageService _imageService = ProfileImageService();
  final ScrollController _scrollController = ScrollController();
  String? _avatarPath;
  String? _backgroundPath;
  double _avatarOffset = 0.5; // 0.0 = top, 0.5 = center, 1.0 = bottom
  double _backgroundOffset = 0.5;
  double _titleOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProfileImages();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show title when scrolled past 100 pixels
    final offset = _scrollController.offset;
    final newOpacity = ((offset - 80) / 40).clamp(0.0, 1.0);
    if (newOpacity != _titleOpacity) {
      setState(() => _titleOpacity = newOpacity);
    }
  }

  Future<void> _loadProfileImages() async {
    final avatarPath = await _imageService.getAvatarPath();
    final backgroundPath = await _imageService.getBackgroundPath();
    final avatarOffset = await _imageService.getAvatarOffset();
    final backgroundOffset = await _imageService.getBackgroundOffset();
    if (mounted) {
      setState(() {
        _avatarPath = avatarPath;
        _backgroundPath = backgroundPath;
        _avatarOffset = avatarOffset;
        _backgroundOffset = backgroundOffset;
      });
    }
  }

  Future<void> _pickAvatar() async {
    final path = await _imageService.pickAndSaveImage('avatar');
    if (path != null && mounted) {
      setState(() => _avatarPath = path);
      // Show position picker for avatar
      _showAvatarPositionPicker();
    }
  }

  Future<void> _pickBackground() async {
    final path = await _imageService.pickAndSaveImage('background');
    if (path != null && mounted) {
      setState(() => _backgroundPath = path);
      // Show position picker
      _showPositionPicker();
    }
  }

  Alignment _getAlignment() {
    // Convert offset (0.0-1.0) to Alignment.y (-1.0 to 1.0)
    return Alignment(0, _backgroundOffset * 2 - 1);
  }

  Alignment _getAvatarAlignment() {
    return Alignment(0, _avatarOffset * 2 - 1);
  }

  Future<void> _showPositionPicker() async {
    if (_backgroundPath == null) return;

    final lang = context.read<LanguageProvider>();
    final result = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder:
            (ctx) => ImagePositionPicker(
              imagePath: _backgroundPath!,
              lang: lang,
              initialOffset: _backgroundOffset,
            ),
      ),
    );

    if (result != null && mounted) {
      await _imageService.setBackgroundOffset(result);
      setState(() => _backgroundOffset = result);
    }
  }

  Future<void> _showAvatarPositionPicker() async {
    if (_avatarPath == null) return;

    final lang = context.read<LanguageProvider>();
    final result = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder:
            (ctx) => ImagePositionPicker(
              imagePath: _avatarPath!,
              lang: lang,
              initialOffset: _avatarOffset,
              isCircular: true, // For avatar circular preview
            ),
      ),
    );

    if (result != null && mounted) {
      await _imageService.setAvatarOffset(result);
      setState(() => _avatarOffset = result);
    }
  }

  /// Helper to get localized gender label
  String _getGenderLabel(String? gender, LanguageProvider lang) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return lang.getText(en: 'Male', vi: 'Nam');
      case 'female':
        return lang.getText(en: 'Female', vi: 'Nữ');
      default:
        return lang.getText(en: 'Not set', vi: 'Chưa đặt');
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, size: 40, color: AppColors.primary),
    );
  }

  void _showImagePickerDialog(BuildContext context, LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  lang.getText(en: 'Change Photo', vi: 'Thay đổi ảnh'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text(
                    lang.getText(en: 'Change Avatar', vi: 'Đổi ảnh đại diện'),
                  ),
                  subtitle: Text(
                    lang.getText(
                      en: 'Select from gallery',
                      vi: 'Chọn từ thư viện',
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAvatar();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.wallpaper,
                      color: AppColors.secondary,
                    ),
                  ),
                  title: Text(
                    lang.getText(en: 'Change Background', vi: 'Đổi ảnh nền'),
                  ),
                  subtitle: Text(
                    lang.getText(
                      en: 'Select from gallery',
                      vi: 'Chọn từ thư viện',
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickBackground();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Fixed background for collapsed app bar - shows BOTTOM of image
          if (_backgroundPath != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).padding.top + kToolbarHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(_backgroundPath!),
                    fit: BoxFit.cover,
                    alignment: _getAlignment(),
                  ),
                  Container(color: Colors.black.withValues(alpha: 0.4)),
                ],
              ),
            ),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Custom App Bar with gradient background
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                stretch: true,
                centerTitle: false,
                backgroundColor:
                    _backgroundPath != null
                        ? Colors.transparent
                        : AppColors.primary,
                // Title shown when collapsed - with opacity animation
                title: Opacity(
                  opacity: _titleOpacity,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Small avatar
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: ClipOval(
                          child:
                              _avatarPath != null
                                  ? Image.file(
                                    File(_avatarPath!),
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    alignment: _getAvatarAlignment(),
                                    errorBuilder:
                                        (_, __, ___) => Container(
                                          color: Colors.white,
                                          child: const Icon(
                                            Icons.person,
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                  )
                                  : Container(
                                    color: Colors.white,
                                    child: const Icon(
                                      Icons.person,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Full Name
                      Text(
                        user?.displayName ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                flexibleSpace: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background - fills entire area
                    _backgroundPath != null
                        ? Image.file(
                          File(_backgroundPath!),
                          fit: BoxFit.cover,
                          alignment: _getAlignment(),
                          errorBuilder:
                              (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                ),
                              ),
                        )
                        : Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                          ),
                        ),
                    // Dark overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                    // Content in FlexibleSpaceBar
                    FlexibleSpaceBar(
                      stretchModes: const [StretchMode.zoomBackground],
                      collapseMode: CollapseMode.none,
                      background: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            // Avatar
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child:
                                  _avatarPath != null
                                      ? ClipOval(
                                        child: Image.file(
                                          File(_avatarPath!),
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          alignment: _getAvatarAlignment(),
                                          errorBuilder:
                                              (_, __, ___) =>
                                                  _buildDefaultAvatar(),
                                        ),
                                      )
                                      : _buildDefaultAvatar(),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user?.displayName ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    onPressed: () => _showImagePickerDialog(context, lang),
                    icon: const Icon(Icons.edit, color: Colors.white),
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSizes.paddingMd,
                  child: Column(
                    children: [
                      const SizedBox(height: AppSizes.md),
                      _buildPersonalInfo(context, lang, user),
                      const SizedBox(height: AppSizes.lg),
                      _buildStats(context, lang, user),
                      const SizedBox(height: AppSizes.lg),
                      _buildGoalCard(context, lang, user),
                      const SizedBox(height: AppSizes.lg),
                      _buildSettingsMenu(context, lang),
                      const SizedBox(height: AppSizes.lg),
                      _buildLogoutButton(context, lang, auth),
                      const SizedBox(height: AppSizes.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo(BuildContext context, LanguageProvider lang, user) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                lang.getText(
                  en: 'Personal Information',
                  vi: 'Thông tin cá nhân',
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          _buildInfoRow(
            context,
            icon: Icons.badge_outlined,
            label: lang.getText(en: 'Username', vi: 'Tên người dùng'),
            value: user?.username ?? '-',
          ),
          _buildInfoRow(
            context,
            icon: Icons.wc_outlined,
            label: lang.getText(en: 'Gender', vi: 'Giới tính'),
            value: _getGenderLabel(user?.gender, lang),
          ),
          _buildInfoRow(
            context,
            icon: Icons.cake_outlined,
            label: lang.getText(en: 'Date of Birth', vi: 'Ngày sinh'),
            value:
                user?.dateOfBirth != null
                    ? dateFormat.format(user!.dateOfBirth!)
                    : lang.getText(en: 'Not set', vi: 'Chưa đặt'),
          ),
          _buildInfoRow(
            context,
            icon: Icons.calendar_today_outlined,
            label: lang.getText(en: 'Age', vi: 'Tuổi'),
            value:
                user?.age != null
                    ? '${user!.age} ${lang.getText(en: 'years old', vi: 'tuổi')}'
                    : lang.getText(en: 'Not set', vi: 'Chưa đặt'),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              SizedBox(
                width: 100, // Fixed width for label
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }

  Widget _buildGoalCard(BuildContext context, LanguageProvider lang, user) {
    // Map goal enum values to display labels
    String getGoalLabel(String? goalValue) {
      switch (goalValue) {
        case 'maintain_weight':
          return lang.getText(en: 'Maintain Weight', vi: 'Duy trì cân nặng');
        case 'build_muscle':
          return lang.getText(en: 'Build Muscle', vi: 'Tăng cơ');
        case 'lose_weight':
          return lang.getText(en: 'Lose Weight', vi: 'Giảm cân');
        default:
          return lang.getText(en: 'Not set', vi: 'Chưa đặt');
      }
    }

    final goalValue = user?.goal;
    final goal = getGoalLabel(goalValue);

    IconData goalIcon;
    Color goalColor;

    if (goalValue == 'build_muscle') {
      goalIcon = Icons.fitness_center;
      goalColor = AppColors.warning; // Orange
    } else if (goalValue == 'lose_weight') {
      goalIcon = Icons.directions_run;
      goalColor = AppColors.info; // Blue
    } else if (goalValue == 'maintain_weight') {
      goalIcon = Icons.balance;
      goalColor = AppColors.success; // Green
    } else {
      // No goal set
      goalIcon = Icons.help_outline;
      goalColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            goalColor.withValues(alpha: 0.1),
            goalColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: goalColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: goalColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(goalIcon, color: goalColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.getText(en: 'Your Goal', vi: 'Mục tiêu của bạn'),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  goal,
                  style: TextStyle(
                    color: goalColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showGoalsDialog(context, lang),
            icon: Icon(Icons.edit_outlined, color: goalColor),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    LanguageProvider lang,
    AuthProvider auth,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(context, lang, auth),
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: Text(
          lang.getText(en: 'Logout', vi: 'Đăng xuất'),
          style: const TextStyle(color: AppColors.error),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildStats(context, lang, user) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            icon: Icons.height,
            label: lang.getText(en: 'Height', vi: 'Chiều cao'),
            value: user?.height != null ? '${user!.height!.toInt()} cm' : '--',
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: _StatItem(
            icon: Icons.monitor_weight,
            label: lang.getText(en: 'Weight', vi: 'Cân nặng'),
            value: user?.weight != null ? '${user!.weight!.toInt()} kg' : '--',
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: _StatItem(
            icon: Icons.speed,
            label: 'BMI',
            value: user?.bmi?.toStringAsFixed(1) ?? '--',
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsMenu(BuildContext context, LanguageProvider lang) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingsItem(
            icon: Icons.person_outline,
            title: lang.getText(en: 'Edit Profile', vi: 'Chỉnh sửa hồ sơ'),
            onTap:
                () => _showEditProfileDialog(
                  context,
                  lang,
                  context.read<AuthProvider>(),
                ),
          ),
          const Divider(height: 1),
          _SettingsItem(
            icon: Icons.language,
            title: lang.getText(en: 'Language', vi: 'Ngôn ngữ'),
            subtitle: lang.isEnglish ? 'English' : 'Tiếng Việt',
            onTap: () {
              _showLanguageDialog(context, lang);
            },
          ),
          const Divider(height: 1),
          _SettingsItem(
            icon: Icons.track_changes,
            title: lang.getText(en: 'Goals', vi: 'Mục tiêu'),
            onTap: () => _showGoalsDialog(context, lang),
          ),
          const Divider(height: 1),
          _SettingsItem(
            icon: Icons.notifications_outlined,
            title: lang.getText(en: 'Notifications', vi: 'Thông báo'),
            onTap: () => _showNotificationsSettings(context, lang),
          ),
          const Divider(height: 1),
          _SettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: lang.getText(en: 'Privacy', vi: 'Quyền riêng tư'),
            onTap:
                () =>
                    _showInfoDialog(context, lang, 'Privacy', 'Quyền riêng tư'),
          ),
          const Divider(height: 1),
          _SettingsItem(
            icon: Icons.help_outline,
            title: lang.getText(en: 'Help & Support', vi: 'Trợ giúp'),
            onTap:
                () => _showInfoDialog(
                  context,
                  lang,
                  'Help & Support',
                  'Trợ giúp',
                ),
          ),
          const Divider(height: 1),
          _SettingsItem(
            icon: Icons.play_circle_outline,
            title: lang.getText(en: 'View Onboarding', vi: 'Xem lại hướng dẫn'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OnboardingFlowScreen(isReview: true),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    LanguageProvider lang, [
    AuthProvider? auth,
  ]) {
    final currentUser = auth?.currentUser;
    final usernameController = TextEditingController(
      text: currentUser?.username ?? '',
    );
    final heightController = TextEditingController(
      text: currentUser?.height?.toStringAsFixed(0) ?? '',
    );
    final weightController = TextEditingController(
      text: currentUser?.weight?.toStringAsFixed(0) ?? '',
    );
    String? selectedGender = currentUser?.gender;

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(
                    lang.getText(en: 'Edit Profile', vi: 'Chỉnh sửa hồ sơ'),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            labelText: lang.getText(
                              en: 'Username',
                              vi: 'Tên người dùng',
                            ),
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedGender,
                          decoration: InputDecoration(
                            labelText: lang.getText(
                              en: 'Gender',
                              vi: 'Giới tính',
                            ),
                            prefixIcon: const Icon(Icons.wc),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'male',
                              child: Text(lang.getText(en: 'Male', vi: 'Nam')),
                            ),
                            DropdownMenuItem(
                              value: 'female',
                              child: Text(lang.getText(en: 'Female', vi: 'Nữ')),
                            ),
                          ],
                          onChanged:
                              (value) => setState(() => selectedGender = value),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: heightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.getText(
                              en: 'Height (cm)',
                              vi: 'Chiều cao (cm)',
                            ),
                            prefixIcon: const Icon(Icons.height),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: weightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.getText(
                              en: 'Weight (kg)',
                              vi: 'Cân nặng (kg)',
                            ),
                            prefixIcon: const Icon(Icons.monitor_weight),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(lang.getText(en: 'Cancel', vi: 'Hủy')),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // Capture context before async
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          await auth?.updateProfile(
                            username: usernameController.text.trim(),
                            gender: selectedGender,
                            height: double.tryParse(heightController.text),
                            weight: double.tryParse(weightController.text),
                          );

                          navigator.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                lang.getText(
                                  en: 'Profile updated!',
                                  vi: 'Đã cập nhật hồ sơ!',
                                ),
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                lang.getText(
                                  en: 'Failed to update profile',
                                  vi: 'Không thể cập nhật hồ sơ',
                                ),
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      child: Text(lang.getText(en: 'Save', vi: 'Lưu')),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showGoalsDialog(BuildContext context, LanguageProvider lang) {
    final auth = context.read<AuthProvider>();
    final currentGoal = auth.currentUser?.goal;

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(lang.getText(en: 'Your Goals', vi: 'Mục tiêu của bạn')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGoalOption(
                  context: dialogContext,
                  parentContext: context,
                  auth: auth,
                  lang: lang,
                  goalId: 'maintain_weight',
                  icon: Icons.balance,
                  color: AppColors.success, // Green
                  label: lang.getText(
                    en: 'Maintain Weight',
                    vi: 'Duy trì cân nặng',
                  ),
                  isSelected: currentGoal == 'maintain_weight',
                ),
                _buildGoalOption(
                  context: dialogContext,
                  parentContext: context,
                  auth: auth,
                  lang: lang,
                  goalId: 'build_muscle',
                  icon: Icons.fitness_center,
                  color: AppColors.warning, // Orange
                  label: lang.getText(en: 'Build Muscle', vi: 'Tăng cơ'),
                  isSelected: currentGoal == 'build_muscle',
                ),
                _buildGoalOption(
                  context: dialogContext,
                  parentContext: context,
                  auth: auth,
                  lang: lang,
                  goalId: 'lose_weight',
                  icon: Icons.directions_run,
                  color: AppColors.info, // Blue
                  label: lang.getText(en: 'Lose Weight', vi: 'Giảm cân'),
                  isSelected: currentGoal == 'lose_weight',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(lang.getText(en: 'Close', vi: 'Đóng')),
              ),
            ],
          ),
    );
  }

  Widget _buildGoalOption({
    required BuildContext context,
    required BuildContext parentContext,
    required AuthProvider auth,
    required LanguageProvider lang,
    required String goalId,
    required IconData icon,
    required Color color,
    required String label,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing:
          isSelected
              ? const Icon(Icons.check_circle, color: AppColors.success)
              : const Icon(Icons.circle_outlined, color: AppColors.border),
      onTap: () async {
        Navigator.pop(context);

        // Show loading
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(
            content: Text(
              lang.getText(en: 'Updating goal...', vi: 'Đang cập nhật...'),
            ),
            duration: const Duration(seconds: 1),
          ),
        );

        // Update goal via API
        final success = await auth.updateUserGoal(goalId);

        // Check if widget is still mounted before using context
        if (!context.mounted) return;

        if (success) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(
              content: Text(
                lang.getText(en: 'Goal updated!', vi: 'Đã cập nhật mục tiêu!'),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(
              content: Text(
                lang.getText(en: 'Failed to update', vi: 'Cập nhật thất bại'),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }

  void _showNotificationsSettings(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(lang.getText(en: 'Notifications', vi: 'Thông báo')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  value: true,
                  onChanged: (v) {},
                  title: Text(
                    lang.getText(en: 'Workout reminders', vi: 'Nhắc tập luyện'),
                  ),
                  secondary: const Icon(Icons.fitness_center),
                ),
                SwitchListTile(
                  value: true,
                  onChanged: (v) {},
                  title: Text(
                    lang.getText(en: 'Meal reminders', vi: 'Nhắc bữa ăn'),
                  ),
                  secondary: const Icon(Icons.restaurant),
                ),
                SwitchListTile(
                  value: false,
                  onChanged: (v) {},
                  title: Text(
                    lang.getText(en: 'Weekly reports', vi: 'Báo cáo tuần'),
                  ),
                  secondary: const Icon(Icons.analytics),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.getText(en: 'Close', vi: 'Đóng')),
              ),
            ],
          ),
    );
  }

  void _showInfoDialog(
    BuildContext context,
    LanguageProvider lang,
    String titleEn,
    String titleVi,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(lang.getText(en: titleEn, vi: titleVi)),
            content: Text(
              lang.getText(
                en: 'This feature will be available in a future update.',
                vi: 'Tính năng này sẽ có trong bản cập nhật tới.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.getText(en: 'OK', vi: 'OK')),
              ),
            ],
          ),
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              lang.getText(en: 'Select Language', vi: 'Chọn ngôn ngữ'),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Text('🇺🇸'),
                  title: const Text('English'),
                  trailing:
                      lang.isEnglish
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                  onTap: () {
                    lang.setLanguage('en');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Text('🇻🇳'),
                  title: const Text('Tiếng Việt'),
                  trailing:
                      lang.isVietnamese
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                  onTap: () {
                    lang.setLanguage('vi');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    LanguageProvider lang,
    AuthProvider auth,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(lang.getText(en: 'Logout', vi: 'Đăng xuất')),
            content: Text(
              lang.getText(
                en: 'Are you sure you want to logout?',
                vi: 'Bạn có chắc muốn đăng xuất?',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.getText(en: 'Cancel', vi: 'Hủy')),
              ),
              ElevatedButton(
                onPressed: () {
                  auth.logout();
                  Navigator.pop(context);
                },
                child: Text(lang.getText(en: 'Logout', vi: 'Đăng xuất')),
              ),
            ],
          ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: AppSizes.iconLg),
          const SizedBox(height: AppSizes.sm),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}
