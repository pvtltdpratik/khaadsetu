class EarningsFakeDataSource {
  Future<double> fetchCommissionRatePercent() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 5.0;
  }
}
