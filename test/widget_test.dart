import 'package:flutter_test/flutter_test.dart';

import 'package:greensitepvdesignerteam750app/main.dart';

void main() {
  test('photovoltaic calculation matches academic example shape', () {
    final result = calculate(
      SiteProfile.demo(),
      EquipmentItem.demoItems(),
      const SimulationInputs(),
    );

    expect(result.totalPowerWatts, 1750);
    expect(result.dailyEnergyWh, 35600);
    expect(result.numberOfPanels, 26);
    expect(result.numberOfBatteries, 10);
  });
}
