import 'package:flutter/material.dart';

/// Helper class for translating static values to Vietnamese
class TranslationHelper {
  /// Translate exercise category
  static String translateCategory(BuildContext context, String category) {
    final isVietnamese = Localizations.localeOf(context).languageCode == 'vi';
    if (!isVietnamese) return category;

    switch (category.toLowerCase()) {
      case 'strength':
        return 'Sức mạnh';
      case 'cardio':
        return 'Cardio';
      case 'stretching':
        return 'Giãn cơ';
      case 'plyometrics':
        return 'Bật nhảy';
      case 'powerlifting':
        return 'Cử tạ';
      case 'strongman':
        return 'Strongman';
      case 'olympic weightlifting':
        return 'Cử tạ Olympic';
      default:
        return category;
    }
  }

  /// Translate exercise equipment
  static String translateEquipment(BuildContext context, String equipment) {
    final isVietnamese = Localizations.localeOf(context).languageCode == 'vi';
    if (!isVietnamese) return equipment;

    switch (equipment.toLowerCase()) {
      case 'body only':
        return 'Không dụng cụ';
      case 'dumbbell':
        return 'Tạ đơn';
      case 'barbell':
        return 'Tạ đòn';
      case 'kettlebells':
        return 'Tạ ấm';
      case 'machine':
        return 'Máy tập';
      case 'cable':
        return 'Cáp kéo';
      case 'bands':
        return 'Dây kháng lực';
      case 'medicine ball':
        return 'Bóng tập';
      case 'exercise ball':
        return 'Bóng yoga';
      case 'foam roll':
        return 'Con lăn foam';
      case 'e-z curl bar':
        return 'Thanh cong EZ';
      case 'pull-up bar':
      case 'other':
        return 'Xà đơn';
      default:
        return equipment;
    }
  }

  /// Translate muscle name
  static String translateMuscle(BuildContext context, String muscle) {
    final isVietnamese = Localizations.localeOf(context).languageCode == 'vi';
    if (!isVietnamese) return muscle;

    switch (muscle.toLowerCase()) {
      // Main muscle groups
      case 'chest':
        return 'Ngực';
      case 'back':
        return 'Lưng';
      case 'shoulders':
        return 'Vai';
      case 'biceps':
        return 'Bắp tay trước';
      case 'triceps':
        return 'Bắp tay sau';
      case 'forearms':
        return 'Cẳng tay';
      case 'abdominals':
        return 'Cơ bụng';
      case 'quadriceps':
        return 'Đùi trước';
      case 'hamstrings':
        return 'Đùi sau';
      case 'glutes':
        return 'Mông';
      case 'calves':
        return 'Bắp chân';
      case 'traps':
        return 'Cơ thang';
      case 'lats':
        return 'Cơ lưng xô';
      case 'lower back':
        return 'Lưng dưới';
      case 'middle back':
        return 'Lưng giữa';
      case 'neck':
        return 'Cổ';
      case 'adductors':
        return 'Đùi trong';
      case 'abductors':
        return 'Đùi ngoài';
      default:
        return muscle;
    }
  }

  /// Translate exercise level
  static String translateLevel(BuildContext context, String level) {
    final isVietnamese = Localizations.localeOf(context).languageCode == 'vi';
    if (!isVietnamese) return level;

    switch (level.toLowerCase()) {
      case 'beginner':
        return 'Cơ bản';
      case 'intermediate':
        return 'Trung bình';
      case 'expert':
      case 'advanced':
        return 'Nâng cao';
      default:
        return level;
    }
  }

  /// Translate recipe category
  static String translateRecipeCategory(BuildContext context, String category) {
    final isVietnamese = Localizations.localeOf(context).languageCode == 'vi';
    if (!isVietnamese) return category;

    switch (category.toLowerCase()) {
      case 'beef':
        return 'Thịt bò';
      case 'chicken':
        return 'Thịt gà';
      case 'pork':
        return 'Thịt heo';
      case 'lamb':
        return 'Thịt cừu';
      case 'goat':
        return 'Thịt dê';
      case 'seafood':
        return 'Hải sản';
      case 'vegetarian':
        return 'Chay';
      case 'vegan':
        return 'Thuần chay';
      case 'pasta':
        return 'Mì Ý';
      case 'dessert':
        return 'Tráng miệng';
      case 'breakfast':
        return 'Bữa sáng';
      case 'side':
        return 'Món phụ';
      case 'starter':
        return 'Khai vị';
      case 'miscellaneous':
        return 'Khác';
      default:
        return category;
    }
  }

  /// Translate recipe area/cuisine
  static String translateRecipeArea(BuildContext context, String area) {
    final isVietnamese = Localizations.localeOf(context).languageCode == 'vi';
    if (!isVietnamese) return area;

    switch (area.toLowerCase()) {
      case 'american':
        return 'Mỹ';
      case 'british':
        return 'Anh';
      case 'canadian':
        return 'Canada';
      case 'chinese':
        return 'Trung Quốc';
      case 'croatian':
        return 'Croatia';
      case 'dutch':
        return 'Hà Lan';
      case 'egyptian':
        return 'Ai Cập';
      case 'filipino':
        return 'Philippines';
      case 'french':
        return 'Pháp';
      case 'greek':
        return 'Hy Lạp';
      case 'indian':
        return 'Ấn Độ';
      case 'irish':
        return 'Ireland';
      case 'italian':
        return 'Ý';
      case 'jamaican':
        return 'Jamaica';
      case 'japanese':
        return 'Nhật Bản';
      case 'kenyan':
        return 'Kenya';
      case 'malaysian':
        return 'Malaysia';
      case 'mexican':
        return 'Mexico';
      case 'moroccan':
        return 'Morocco';
      case 'polish':
        return 'Ba Lan';
      case 'portuguese':
        return 'Bồ Đào Nha';
      case 'russian':
        return 'Nga';
      case 'spanish':
        return 'Tây Ban Nha';
      case 'thai':
        return 'Thái Lan';
      case 'tunisian':
        return 'Tunisia';
      case 'turkish':
        return 'Thổ Nhĩ Kỳ';
      case 'ukrainian':
        return 'Ukraine';
      case 'vietnamese':
        return 'Việt Nam';
      case 'unknown':
        return 'Không rõ';
      default:
        return area;
    }
  }
}
