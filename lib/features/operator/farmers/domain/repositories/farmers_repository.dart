import '../entities/farmer.dart';

abstract class FarmersRepository {
  Future<List<Farmer>> getFarmers();
  Future<Farmer> getFarmerById(String id);
}
