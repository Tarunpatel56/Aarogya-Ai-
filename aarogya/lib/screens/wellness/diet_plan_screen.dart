import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/diet_service.dart';

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key});

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> {
  final DietService _dietService = DietService();
  bool _isLoading = true;
  UserDietProfile? _profile;
  List<DietMealItem> _meals = [];
  MedicalDietAdvisory? _advisory;
  final Set<String> _eatenMeals = {};

  final List<String> _allConditions = [
    'None',
    'Diabetes',
    'Hypertension',
    'High Uric Acid',
    'Fatty Liver',
    'Thyroid',
    'Acidity',
    'Fever / Infection',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileAndPlan();
  }

  Future<void> _loadProfileAndPlan() async {
    setState(() => _isLoading = true);
    final saved = await _dietService.getProfile();
    if (saved != null) {
      _profile = saved;
      _meals = _dietService.generateMeals(saved);
      _advisory = _dietService.getMedicalAdvisory(saved.medicalConditions);
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _openProfileEditor({bool isFirstTime = false}) {
    final ageCtrl = TextEditingController(text: _profile?.age.toString() ?? '28');
    final heightCtrl = TextEditingController(text: _profile?.heightCm.toString() ?? '172');
    final weightCtrl = TextEditingController(text: _profile?.weightKg.toString() ?? '68');
    String gender = _profile?.gender ?? 'Male';
    String activity = _profile?.activityLevel ?? 'Moderately Active';
    String goal = _profile?.fitnessGoal ?? 'Weight Loss';
    String dietType = _profile?.dietType ?? 'Pure Vegetarian';
    List<String> selectedConditions = List<String>.from(_profile?.medicalConditions ?? ['None']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isFirstTime ? 'Setup Your Body & Diet Profile' : 'Edit Body & Medical Profile',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your personalized diet plan is medically tailored to your BMI, diet preferences, and health conditions.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // Gender Selector
                Row(
                  children: [
                    const Text('Gender: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    ...['Male', 'Female', 'Other'].map(
                      (g) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(g, style: TextStyle(fontSize: 12, color: gender == g ? Colors.white : AppColors.textPrimary)),
                          selected: gender == g,
                          selectedColor: AppColors.primaryTeal,
                          onSelected: (val) {
                            if (val) setModalState(() => gender = g);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Age, Height, Weight Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Age (Yrs)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: heightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: weightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Dietary Preference (Veg vs Non-Veg vs Eggetarian vs Vegan)
                const Text('Diet Preference (Food Type):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: dietType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    'Pure Vegetarian',
                    'Non-Vegetarian',
                    'Eggetarian',
                    'Vegan',
                  ].map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => dietType = val);
                  },
                ),
                const SizedBox(height: 14),

                // Fitness / Health Goal
                const Text('Primary Goal:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: goal,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    'Weight Loss',
                    'Muscle Gain',
                    'Maintain Weight',
                    'Diabetes Control',
                    'Heart Health',
                  ].map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => goal = val);
                  },
                ),
                const SizedBox(height: 14),

                // Activity Level
                const Text('Physical Activity Level:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: activity,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    'Sedentary',
                    'Lightly Active',
                    'Moderately Active',
                    'Very Active',
                  ].map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => activity = val);
                  },
                ),
                const SizedBox(height: 14),

                // Medical Conditions / Illnesses
                const Text('Current Illness / Medical Conditions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _allConditions.map((cond) {
                    final isSelected = selectedConditions.contains(cond);
                    return FilterChip(
                      label: Text(
                        cond,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: cond == 'None' ? AppColors.primaryTeal : const Color(0xFFDC2626),
                      backgroundColor: const Color(0xFFF1F5F9),
                      onSelected: (selected) {
                        setModalState(() {
                          if (cond == 'None') {
                            selectedConditions = ['None'];
                          } else {
                            selectedConditions.remove('None');
                            if (selected) {
                              selectedConditions.add(cond);
                            } else {
                              selectedConditions.remove(cond);
                            }
                            if (selectedConditions.isEmpty) selectedConditions.add('None');
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final age = int.tryParse(ageCtrl.text.trim()) ?? 28;
                      final height = double.tryParse(heightCtrl.text.trim()) ?? 172.0;
                      final weight = double.tryParse(weightCtrl.text.trim()) ?? 68.0;

                      final newProfile = UserDietProfile(
                        age: age,
                        gender: gender,
                        heightCm: height,
                        weightKg: weight,
                        activityLevel: activity,
                        fitnessGoal: goal,
                        dietType: dietType,
                        medicalConditions: selectedConditions,
                        lastUpdated: DateTime.now().toIso8601String(),
                      );

                      await _dietService.saveProfile(newProfile);

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        setState(() {
                          _profile = newProfile;
                          _meals = _dietService.generateMeals(newProfile);
                          _advisory = _dietService.getMedicalAdvisory(newProfile.medicalConditions);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Personalized Diet Plan generated successfully!'),
                            backgroundColor: Color(0xFF16A34A),
                          ),
                        );
                      }
                    },
                    child: Text(
                      isFirstTime ? 'Generate My Diet Plan' : 'Save & Update Diet Plan',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBmiColor(String cat) {
    switch (cat) {
      case 'Normal Weight':
        return const Color(0xFF16A34A);
      case 'Underweight':
        return const Color(0xFF0284C7);
      case 'Overweight':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFFDC2626);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(
          title: const Text('Daily Diet & Nutrition Plan'),
          backgroundColor: Colors.white,
          elevation: 0.5,
          foregroundColor: AppColors.textPrimary,
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(
          title: const Text('Daily Diet Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          foregroundColor: AppColors.textPrimary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restaurant_menu_rounded, size: 48, color: AppColors.primaryTeal),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Personalized Clinical Diet Plan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tell us your body details, diet choice (Veg/Non-Veg), and any health conditions to generate a customized 7-meal daily nutrition schedule.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Setup Body Profile & Diet Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () => _openProfileEditor(isFirstTime: true),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final p = _profile!;
    final adv = _advisory ?? _dietService.getMedicalAdvisory(p.medicalConditions);
    final hasCondition = p.medicalConditions.any((c) => c != 'None');

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Daily Diet Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            tooltip: 'Edit Profile & Details',
            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryTeal),
            onPressed: () => _openProfileEditor(isFirstTime: false),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Body & Diet Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${p.gender}, ${p.age} Yrs • ${p.weightKg.toInt()} kg / ${p.heightCm.toInt()} cm',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        InkWell(
                          onTap: () => _openProfileEditor(isFirstTime: false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.edit, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('Edit', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        // BMI Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'BMI: ${p.bmi} (${p.bmiCategory})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getBmiColor(p.bmiCategory),
                            ),
                          ),
                        ),
                        // Diet Type Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.dietType == 'Non-Vegetarian' ? '🍗 Non-Veg' : (p.dietType == 'Pure Vegetarian' ? '🌱 Pure Veg' : p.dietType),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        // Goal Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '🎯 ${p.fitnessGoal}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    if (hasCondition) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.healing_rounded, color: Color(0xFFFCA5A5), size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Conditions: ${p.medicalConditions.join(", ")}',
                              style: const TextStyle(color: Color(0xFFFEE2E2), fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Nutrition Target Strip
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMacroItem('Daily Calories', '${p.targetCalories}', 'kcal', const Color(0xFF0F766E)),
                    _buildMacroItem('Protein', '${(p.targetCalories * 0.22 / 4).round()}', 'g', const Color(0xFF2563EB)),
                    _buildMacroItem('Carbs', '${(p.targetCalories * 0.52 / 4).round()}', 'g', const Color(0xFFD97706)),
                    _buildMacroItem('Water', '${p.targetWaterLitres}', 'L', const Color(0xFF0284C7)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Condition Specific Food Guidelines (Eat vs Strictly Avoid)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.health_and_safety_rounded, color: AppColors.primaryTeal, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          hasCondition ? 'Clinical Food Rules for Your Health' : 'General Healthy Food Guidelines',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Foods to Eat (Green Box)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Foods to Eat (Kya Khana Chahiye):',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...adv.foodsToEat.map(
                            (food) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(food, style: const TextStyle(fontSize: 12, color: Color(0xFF166534))),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Foods to Avoid (Red Box)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Foods to Avoid (Kya Nahi Khana Chahiye):',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...adv.foodsToAvoid.map(
                            (food) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('✕ ', style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(food, style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B))),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '💡 Tip: ${adv.clinicalTip}',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Daily Meal Schedule Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daily Meal Schedule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${_eatenMeals.length} of ${_meals.length} meals completed',
                    style: const TextStyle(fontSize: 12, color: AppColors.primaryTeal, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 5. Meals List
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _meals.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final meal = _meals[index];
                  final isEaten = _eatenMeals.contains(meal.mealName);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isEaten ? const Color(0xFFBBF7D0) : AppColors.cardBorder,
                      ),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isEaten ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                meal.mealName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isEaten ? const Color(0xFF15803D) : AppColors.primaryTeal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              meal.timing,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            const Spacer(),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                isEaten ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                color: isEaten ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                size: 24,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isEaten) {
                                    _eatenMeals.remove(meal.mealName);
                                  } else {
                                    _eatenMeals.add(meal.mealName);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          meal.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isEaten ? const Color(0xFF15803D) : AppColors.textPrimary,
                            decoration: isEaten ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          meal.description,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${meal.calories} kcal',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${meal.proteinGrams}g Protein',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                meal.keyNutrient,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Bottom Re-generate Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    side: const BorderSide(color: AppColors.primaryTeal),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Edit Details & Regenerate Diet Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _openProfileEditor(isFirstTime: false),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(width: 2),
            Text(unit, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
