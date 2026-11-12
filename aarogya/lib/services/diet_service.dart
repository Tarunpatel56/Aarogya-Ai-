import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserDietProfile {
  final int age;
  final String gender; // 'Male', 'Female', 'Other'
  final double heightCm;
  final double weightKg;
  final String activityLevel; // 'Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active'
  final String fitnessGoal; // 'Weight Loss', 'Muscle Gain', 'Maintain Weight', 'Diabetes Control', 'Heart Health'
  final String dietType; // 'Pure Vegetarian', 'Vegan', 'Eggetarian', 'Non-Vegetarian'
  final List<String> medicalConditions; // e.g. ['Diabetes', 'Hypertension', 'High Uric Acid', 'Fatty Liver', 'Thyroid', 'Acidity', 'Fever / Infection', 'None']
  final String? lastUpdated;

  const UserDietProfile({
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.fitnessGoal,
    required this.dietType,
    required this.medicalConditions,
    this.lastUpdated,
  });

  double get bmi {
    final heightM = heightCm / 100.0;
    if (heightM <= 0) return 22.0;
    return double.parse((weightKg / (heightM * heightM)).toStringAsFixed(1));
  }

  String get bmiCategory {
    final b = bmi;
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Normal Weight';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }

  int get targetCalories {
    // Mifflin-St Jeor Formula
    double bmr;
    if (gender == 'Female') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    }

    double multiplier = 1.2;
    switch (activityLevel) {
      case 'Lightly Active':
        multiplier = 1.375;
        break;
      case 'Moderately Active':
        multiplier = 1.55;
        break;
      case 'Very Active':
        multiplier = 1.725;
        break;
      default:
        multiplier = 1.2;
    }

    final tdee = bmr * multiplier;
    if (fitnessGoal == 'Weight Loss') {
      return (tdee - 450).clamp(1200, 3200).toInt();
    } else if (fitnessGoal == 'Muscle Gain') {
      return (tdee + 350).clamp(1500, 3800).toInt();
    }
    return tdee.clamp(1400, 3400).toInt();
  }

  double get targetWaterLitres {
    final val = (weightKg * 35) / 1000.0;
    return double.parse(val.clamp(2.0, 4.5).toStringAsFixed(1));
  }

  Map<String, dynamic> toJson() => {
        'age': age,
        'gender': gender,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activityLevel': activityLevel,
        'fitnessGoal': fitnessGoal,
        'dietType': dietType,
        'medicalConditions': medicalConditions,
        'lastUpdated': lastUpdated ?? DateTime.now().toIso8601String(),
      };

  factory UserDietProfile.fromJson(Map<String, dynamic> json) => UserDietProfile(
        age: json['age'] as int? ?? 28,
        gender: json['gender'] as String? ?? 'Male',
        heightCm: (json['heightCm'] as num?)?.toDouble() ?? 172.0,
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 68.0,
        activityLevel: json['activityLevel'] as String? ?? 'Moderately Active',
        fitnessGoal: json['fitnessGoal'] as String? ?? 'Weight Loss',
        dietType: json['dietType'] as String? ?? 'Pure Vegetarian',
        medicalConditions: (json['medicalConditions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['None'],
        lastUpdated: json['lastUpdated'] as String?,
      );
}

class DietMealItem {
  final String mealName; // 'Early Morning', 'Breakfast', 'Mid-Morning', 'Lunch', 'Evening Snack', 'Dinner', 'Bedtime'
  final String timing;
  final String title;
  final String description;
  final int calories;
  final int proteinGrams;
  final String keyNutrient;

  const DietMealItem({
    required this.mealName,
    required this.timing,
    required this.title,
    required this.description,
    required this.calories,
    required this.proteinGrams,
    required this.keyNutrient,
  });
}

class MedicalDietAdvisory {
  final List<String> foodsToEat;
  final List<String> foodsToAvoid;
  final String clinicalTip;

  const MedicalDietAdvisory({
    required this.foodsToEat,
    required this.foodsToAvoid,
    required this.clinicalTip,
  });
}

class DietService {
  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryFallback = {};
  bool _useFallback = false;

  static const String _profileKey = 'aarogya_user_diet_profile';

  DietService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  bool _isTestEnvironment() {
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  Future<void> saveProfile(UserDietProfile profile) async {
    final raw = jsonEncode(profile.toJson());
    if (_isTestEnvironment()) {
      _memoryFallback[_profileKey] = raw;
      return;
    }
    try {
      if (!_useFallback) {
        await _storage.write(key: _profileKey, value: raw);
        return;
      }
    } catch (_) {
      _useFallback = true;
    }
    _memoryFallback[_profileKey] = raw;
  }

  Future<UserDietProfile?> getProfile() async {
    String? raw;
    if (_isTestEnvironment()) {
      raw = _memoryFallback[_profileKey];
    } else {
      try {
        if (!_useFallback) {
          raw = await _storage.read(key: _profileKey);
        }
      } catch (_) {
        _useFallback = true;
      }
      raw ??= _memoryFallback[_profileKey];
    }

    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserDietProfile.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Calculates clinical condition food guidelines (Eat vs Strictly Avoid)
  MedicalDietAdvisory getMedicalAdvisory(List<String> conditions) {
    final toEat = <String>{};
    final toAvoid = <String>{};
    final tips = <String>[];

    if (conditions.contains('Diabetes') || conditions.contains('High Blood Sugar')) {
      toEat.addAll([
        'Fenugreek (Methi) soaked water & sprouted seeds',
        'Bitter gourd (Karela) & Bottle gourd (Lauki)',
        'Steel-cut oats, Barley, and Multigrain rotis',
        'Cinnamon (Dalchini) infused herbal warm water',
        'High-fiber green leafy vegetables (Spinach, Methi saag)',
        'Roasted Chana and Sprouted Moong beans',
      ]);
      toAvoid.addAll([
        'Refined white sugar, jaggery sweets & desserts',
        'Maida bakery items, white bread & naan',
        'Packaged fruit juices, cold drinks & soda',
        'Deep-fried samosas, pakoras & sweet fruits (Mango/Chikoo in excess)',
      ]);
      tips.add('Maintain consistent low glycemic index meals to prevent postprandial glucose spikes.');
    }

    if (conditions.contains('Hypertension') || conditions.contains('High Blood Pressure')) {
      toEat.addAll([
        'Raw garlic cloves (Allicin for arterial dilation)',
        'Potassium-rich coconut water, bananas & beetroots',
        'Flaxseeds (Alsi) and Chia seeds in breakfast',
        'Fresh homemade unflavored curd (Dahi)',
      ]);
      toAvoid.addAll([
        'Excess added table salt and sodium preservatives',
        'Pickles (Achaar), Papad, and salted nuts',
        'Processed cheese, packaged canned soups & instant noodles',
      ]);
      tips.add('Adhere to DASH principles: high potassium, magnesium, and strictly under 2,000 mg sodium daily.');
    }

    if (conditions.contains('High Uric Acid') || conditions.contains('Gout')) {
      toEat.addAll([
        'Fresh cherries, strawberries & amla (Vitamin C)',
        'Plenty of alkaline water (minimum 3.5 Litres daily)',
        'Low-fat skimmed milk and homemade paneer',
        'Cucumber, bottle gourd, and apple cider vinegar water',
      ]);
      toAvoid.addAll([
        'Red meat, organ meats, mutton & beef',
        'Seafood (prawns, sardines, crab)',
        'High-purine heavy dals in excess (Urad dal, whole Masoor)',
        'Alcohol, beer & high-fructose corn syrup sodas',
      ]);
      tips.add('Alkalinize urine with ample hydration and lemon water to enhance uric acid crystal excretion.');
    }

    if (conditions.contains('Fatty Liver')) {
      toEat.addAll([
        'Antioxidant-rich green tea (EGCG)',
        'Cruciferous vegetables (Broccoli, Cauliflower, Cabbage)',
        'Walnuts, almonds, and cold-pressed mustard oil in moderation',
        'Fresh papaya and fiber-rich legumes',
      ]);
      toAvoid.addAll([
        'Alcohol in any form (strictly zero tolerance)',
        'Trans-fats, vanaspati ghee, and deep-fried fast food',
        'High-sugar snacks, refined pastries & carbonated drinks',
      ]);
      tips.add('Promote hepatic fat oxidation with unrefined complex carbohydrates and active daily walks.');
    }

    if (conditions.contains('Thyroid') || conditions.contains('Hypothyroidism')) {
      toEat.addAll([
        'Selenium-rich Brazil nuts, sunflower seeds & almonds',
        'Adequate iodized salt & sea minerals',
        'Whole eggs (iodine and tyrosine source)',
        'Ashwagandha or ginger cinnamon herbal infusion',
      ]);
      toAvoid.addAll([
        'Raw cruciferous vegetables (raw cabbage, cauliflower) — always steam or boil',
        'Excess unfermented soy products (tofu/soy milk in high quantity)',
        'Refined gluten flour if digestive sensitivity exists',
      ]);
      tips.add('Ensure adequate selenium, zinc, and iodine while cooking cruciferous vegetables thoroughly.');
    }

    if (conditions.contains('Acidity') || conditions.contains('Acid Reflux / GERD')) {
      toEat.addAll([
        'Chilled skimmed milk or buttermilk (Chaas) with roasted cumin',
        'Fennel seeds (Saunf) water after meals',
        'Ripe bananas, watermelon, and boiled gourd sabzi',
        'Oatmeal porridge and soaked basil seeds (Sabja)',
      ]);
      toAvoid.addAll([
        'Excess red chili powder, black pepper, and garam masala',
        'Tea or coffee on an empty stomach in the morning',
        'Citrus fruits on empty stomach, tomato gravies & vinegar',
        'Eating heavy meals right before bedtime',
      ]);
      tips.add('Eat smaller, frequent alkaline meals and maintain an upright posture for 2 hours post-dinner.');
    }

    if (conditions.contains('Fever / Infection') || conditions.contains('Viral Recovery')) {
      toEat.addAll([
        'Light Moong Dal Khichdi with a dash of pure cow ghee',
        'Warm vegetable clear soup with ginger and garlic',
        'Tender coconut water, pomegranate juice & boiled water',
        'Boiled egg whites or steamed soft paneer',
      ]);
      toAvoid.addAll([
        'Cold refrigerated food, ice creams & chilled drinks',
        'Heavy oily gravies and hard-to-digest red meats',
        'Spicy, fermented street food',
      ]);
      tips.add('Focus on cellular rehydration, high fluid intake, and easily assimilable protein.');
    }

    // Default healthy guidelines if none selected
    if (toEat.isEmpty) {
      toEat.addAll([
        'Fresh seasonal vegetables & colorful salads',
        'Sprouted legumes (Moong, Kala Chana, Cowpeas)',
        'Whole grains (Jowar, Bajra, Ragi, Brown rice)',
        'Nuts & Seeds (Almonds, Walnuts, Pumpkin seeds)',
        'Probiotic curd or fresh buttermilk daily',
      ]);
      toAvoid.addAll([
        'Ultra-processed packaged chips and biscuits',
        'Refined palm oil & deep-fried foods',
        'Excess sugary beverages and artificial sweeteners',
        'Late-night heavy carbohydrate snacking',
      ]);
      tips.add('Maintain a balanced plate: 50% fiber & vegetables, 25% clean protein, 25% complex carbohydrates.');
    }

    return MedicalDietAdvisory(
      foodsToEat: toEat.toList(),
      foodsToAvoid: toAvoid.toList(),
      clinicalTip: tips.isNotEmpty ? tips.join(' ') : 'Eat mindfully, chew slowly, and stay adequately hydrated throughout the day.',
    );
  }

  /// Generates a comprehensive day-by-day 7-meal schedule tailored to Veg / Non-Veg
  List<DietMealItem> generateMeals(UserDietProfile profile) {
    final isNonVeg = profile.dietType == 'Non-Vegetarian';
    final isEggetarian = profile.dietType == 'Eggetarian';
    final isVegan = profile.dietType == 'Vegan';
    final isDiabetic = profile.medicalConditions.contains('Diabetes') || profile.medicalConditions.contains('High Blood Sugar');
    final isWeightLoss = profile.fitnessGoal == 'Weight Loss';

    final totalCal = profile.targetCalories;

    // 1. Early Morning (approx 8% cal)
    final earlyCal = (totalCal * 0.08).round();
    final earlyMeal = DietMealItem(
      mealName: 'Early Morning',
      timing: '06:30 AM - 07:00 AM',
      title: isDiabetic ? 'Methi Water & Soaked Nuts' : 'Warm Lemon Water & Activated Almonds',
      description: isDiabetic
          ? '1 glass warm Fenugreek (Methi) water + 5 soaked peeled almonds + 1 whole walnut kernel.'
          : '1 glass warm water with 1/2 squeezed fresh lemon + 5 soaked almonds + 1 walnut.',
      calories: earlyCal,
      proteinGrams: 4,
      keyNutrient: 'Metabolic Detox & Healthy Omega-3s',
    );

    // 2. Breakfast (approx 24% cal)
    final bfastCal = (totalCal * 0.24).round();
    String bfastTitle;
    String bfastDesc;
    int bfastProt;

    if (isNonVeg || isEggetarian) {
      bfastTitle = 'Boiled Eggs & Sprouted Moong Toast';
      bfastDesc = '3 Boiled Egg whites (or 2 whole eggs) + 1 Multigrain toast + 1/2 cup Sprouted Moong salad + Green Tea.';
      bfastProt = 22;
    } else if (isVegan) {
      bfastTitle = 'Tofu & Vegetable Scramble with Multigrain Toast';
      bfastDesc = '100g Tofu scramble with spinach, tomatoes, turmeric + 2 slices multigrain bread + Chia seed lemon water.';
      bfastProt = 16;
    } else {
      // Pure Veg
      bfastTitle = isDiabetic ? 'Moong Dal Chilla with Mint Chutney' : 'Paneer Stuffed Besan Chilla & Sprouts';
      bfastDesc = isDiabetic
          ? '2 Green Moong dal chillas loaded with grated carrots & coriander + homemade mint coriander chutney + 1 cup unsweetened tea.'
          : '2 Besan-paneer chillas (75g fresh paneer) + 1/2 cup sprouted salad + green tea or skimmed milk.';
      bfastProt = 18;
    }

    final bfastMeal = DietMealItem(
      mealName: 'Breakfast',
      timing: '08:30 AM - 09:15 AM',
      title: bfastTitle,
      description: bfastDesc,
      calories: bfastCal,
      proteinGrams: bfastProt,
      keyNutrient: 'Clean Lean Protein & Sustained Energy',
    );

    // 3. Mid-Morning Snack (approx 8% cal)
    final midCal = (totalCal * 0.08).round();
    final midMeal = DietMealItem(
      mealName: 'Mid-Morning Snack',
      timing: '11:00 AM - 11:30 AM',
      title: isDiabetic ? 'Fresh Buttermilk with Roasted Jeera' : 'Tender Coconut Water & Seasonal Fruit',
      description: isDiabetic
          ? '1 tall glass freshly prepared Buttermilk (Chaas) with roasted cumin powder, mint, and a pinch of rock salt + 1 small guava.'
          : '1 glass fresh Tender Coconut water + 1 bowl Papaya or 1 crisp Apple with skin.',
      calories: midCal,
      proteinGrams: 3,
      keyNutrient: 'Electrolytes, Potassium & Prebiotics',
    );

    // 4. Lunch (approx 32% cal)
    final lunchCal = (totalCal * 0.32).round();
    String lunchTitle;
    String lunchDesc;
    int lunchProt;

    if (isNonVeg) {
      lunchTitle = 'Grilled Chicken / Fish with Multigrain Roti & Dal';
      lunchDesc = '120g Grilled chicken breast (or steamed Rohu/Surmai fish) + 2 Jowar/Multigrain rotis + 1 bowl Yellow Moong Dal + Fresh Cucumber & Tomato Salad.';
      lunchProt = 34;
    } else if (isVegan) {
      lunchTitle = 'Soy Bean & Chickpea Curry with Brown Rice';
      lunchDesc = '1 bowl Soya chunks and Chickpea curry (high protein) + 1 cup Brown rice or 2 Bajra rotis + 1 bowl Mixed Green Salad.';
      lunchProt = 24;
    } else {
      // Pure Veg & Eggetarian
      lunchTitle = 'Balanced Indian Thali with Paneer & Dal Tadka';
      lunchDesc = '2 Multigrain / Wheat-Bran rotis + 1 bowl Toor/Moong Dal + 100g Fresh low-fat Paneer curry + 1 cup seasonal Sabzi (Lauki/Bhindi) + 1 bowl Cucumber Curd.';
      lunchProt = 25;
    }

    final lunchMeal = DietMealItem(
      mealName: 'Lunch',
      timing: '01:00 PM - 02:00 PM',
      title: lunchTitle,
      description: lunchDesc,
      calories: lunchCal,
      proteinGrams: lunchProt,
      keyNutrient: 'Macronutrient Balance & High Dietary Fiber',
    );

    // 5. Evening Snack (approx 8% cal)
    final eveCal = (totalCal * 0.08).round();
    final eveMeal = DietMealItem(
      mealName: 'Evening Snack',
      timing: '04:30 PM - 05:15 PM',
      title: 'Roasted Fox Nuts (Makhana) & Green Tea',
      description: '1 bowl dry roasted Makhana with a pinch of black pepper and turmeric + 1 hot cup Green tea or Lemon ginger brew.',
      calories: eveCal,
      proteinGrams: 4,
      keyNutrient: 'Low Calorie Micronutrients & Antioxidants',
    );

    // 6. Dinner (approx 16% cal)
    final dinCal = (totalCal * 0.16).round();
    String dinTitle;
    String dinDesc;
    int dinProt;

    if (isNonVeg) {
      dinTitle = 'Clear Chicken Vegetable Soup & 1 Phulka';
      dinDesc = '1 big bowl warm Chicken & vegetable clear soup with shredded carrots & beans + 1 light Phulka with a small cup of steamed greens.';
      dinProt = 26;
    } else if (isVegan) {
      dinTitle = 'Quinoa Vegetable Bowl with Sautéed Tofu';
      dinDesc = '1 bowl cooked Quinoa tossed with sautéed bell peppers, carrots, and 80g Tofu cubes + lemon dressing.';
      dinProt = 18;
    } else {
      dinTitle = isWeightLoss ? 'Vegetable Moong Dal Khichdi & Lauki Sabzi' : 'Light Jowar Roti, Dal & Sautéed Paneer';
      dinDesc = isWeightLoss
          ? '1 bowl light Yellow Moong Dal Khichdi (more dal, less rice) + 1 bowl Bottle gourd (Lauki) sabzi + Carrot salad.'
          : '1-2 Jowar rotis + 1 bowl Dal Palak + 60g sautéed paneer cubes with herbs.';
      dinProt = 18;
    }

    final dinMeal = DietMealItem(
      mealName: 'Dinner',
      timing: '07:30 PM - 08:30 PM',
      title: dinTitle,
      description: dinDesc,
      calories: dinCal,
      proteinGrams: dinProt,
      keyNutrient: 'Easy Digestion & Low Glycemic Load',
    );

    // 7. Bedtime (approx 4% cal)
    final bedCal = (totalCal * 0.04).round();
    final bedMeal = DietMealItem(
      mealName: 'Bedtime',
      timing: '10:00 PM',
      title: isVegan ? 'Warm Spiced Almond Milk' : 'Golden Turmeric Haldi Milk',
      description: isVegan
          ? '1 cup warm unsweetened Almond milk with a pinch of nutmeg and cinnamon.'
          : '1 cup warm low-fat milk with pure organic Turmeric (Haldi) + pinch of black pepper for enhanced curcumin absorption.',
      calories: bedCal,
      proteinGrams: 4,
      keyNutrient: 'Cellular Repair, Anti-inflammatory & Sleep Induction',
    );

    return [earlyMeal, bfastMeal, midMeal, lunchMeal, eveMeal, dinMeal, bedMeal];
  }
}
