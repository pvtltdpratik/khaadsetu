import '../../domain/entities/farmer.dart';

class FarmersFakeDataSource {
  static final List<Farmer> _farmers = [
    Farmer(
      id: 'farmer-ramesh',
      name: 'Ramesh Patil',
      village: 'Shirur, Pune',
      phone: '+91 98221 XXXXX',
      activeCrop: 'Wheat',
      lastVisitDate: DateTime.now().subtract(const Duration(days: 4)),
      needsFollowUp: false,
      notes: 'Following up on nitrogen top-dressing recommendation.',
    ),
    Farmer(
      id: 'farmer-suresh',
      name: 'Suresh Jadhav',
      village: 'Paithan, Aurangabad',
      phone: '+91 98230 XXXXX',
      activeCrop: 'Cotton',
      lastVisitDate: DateTime.now().subtract(const Duration(days: 18)),
      needsFollowUp: true,
      notes: 'Asked about bollworm spray results — hasn\'t reported back.',
    ),
    Farmer(
      id: 'farmer-anita',
      name: 'Anita Kale',
      village: 'Lasalgaon, Nashik',
      phone: '+91 98221 XXXXX',
      activeCrop: 'Onion',
      lastVisitDate: DateTime.now().subtract(const Duration(days: 1)),
      needsFollowUp: false,
      notes: 'Picked up NPK order today.',
    ),
    Farmer(
      id: 'farmer-vikram',
      name: 'Vikram Deshmukh',
      village: 'Karvir, Kolhapur',
      phone: '+91 98812 XXXXX',
      activeCrop: 'Sugarcane',
      lastVisitDate: DateTime.now().subtract(const Duration(days: 35)),
      needsFollowUp: true,
      notes: 'Waiting to hear how the insurance claim for rain damage went.',
    ),
    Farmer(
      id: 'farmer-meera',
      name: 'Meera Shinde',
      village: 'Shirur, Pune',
      phone: '+91 98501 XXXXX',
      activeCrop: 'Soybean',
      lastVisitDate: DateTime.now().subtract(const Duration(days: 9)),
      needsFollowUp: true,
      notes: 'Reported a fungal spot issue — check if it has spread.',
    ),
    Farmer(
      id: 'farmer-lakshmi',
      name: 'Lakshmi Naik',
      village: 'Shirur, Pune',
      phone: '+91 98904 XXXXX',
      activeCrop: 'Wheat',
      lastVisitDate: DateTime.now().subtract(const Duration(days: 2)),
      needsFollowUp: false,
      notes: 'Considering drip irrigation for next season.',
    ),
  ];

  Future<List<Farmer>> fetchFarmers() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_farmers);
  }

  Future<Farmer> fetchFarmerById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _farmers.firstWhere((f) => f.id == id);
  }
}
