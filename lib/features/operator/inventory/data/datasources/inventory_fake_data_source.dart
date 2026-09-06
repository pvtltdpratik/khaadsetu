import '../../domain/entities/inventory_item.dart';

class InventoryFakeDataSource {
  static final List<InventoryItem> _items = [
    const InventoryItem(
      id: 'inv-urea',
      name: 'Urea Prill 46%',
      unit: 'bag',
      unitPrice: 350,
      currentStock: 8,
      lowStockThreshold: 10,
    ),
    const InventoryItem(
      id: 'inv-dap',
      name: 'DAP 18-46-0',
      unit: 'bag',
      unitPrice: 1450,
      currentStock: 25,
      lowStockThreshold: 10,
    ),
    const InventoryItem(
      id: 'inv-npk',
      name: 'NPK 10-26-26 Complex',
      unit: 'bag',
      unitPrice: 1325,
      currentStock: 5,
      lowStockThreshold: 8,
    ),
    const InventoryItem(
      id: 'inv-vermicompost',
      name: 'Vermicompost',
      unit: 'bag',
      unitPrice: 450,
      currentStock: 40,
      lowStockThreshold: 15,
    ),
    const InventoryItem(
      id: 'inv-biopesticide',
      name: 'Bio-Pesticide Spray',
      unit: 'bottle',
      unitPrice: 320,
      currentStock: 12,
      lowStockThreshold: 5,
    ),
  ];

  Future<List<InventoryItem>> fetchItems() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_items);
  }
}
