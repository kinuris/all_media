import 'package:flutter/material.dart';

class VolumeDisplaySettings extends StatefulWidget {
  const VolumeDisplaySettings({Key? key}) : super(key: key);

  @override
  State<VolumeDisplaySettings> createState() => _VolumeDisplaySettingsState();
}

class _VolumeDisplaySettingsState extends State<VolumeDisplaySettings> {
  String _dropdownValue = 'horizontal-paginated';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[900],
            width: constraints.maxWidth,
            child: Column(
              children: [
                const Text("Resource Reader Mode",
                    style: TextStyle(color: Colors.white)),
                DropdownButton(
                  dropdownColor: Colors.grey[800],
                  items: const [
                    DropdownMenuItem(
                      value: 'horizontal-paginated',
                      child: Text("Horizontal Paginated",
                          style: TextStyle(color: Colors.white)),
                    ),
                    DropdownMenuItem(
                      value: 'vertical-paginated',
                      child: Text("Vertical Paginated",
                          style: TextStyle(color: Colors.white)),
                    ),
                    DropdownMenuItem(
                      value: 'vertical-continuous',
                      child: Text("Vertical Continuous",
                          style: TextStyle(color: Colors.white)),
                    ),
                    DropdownMenuItem(
                      value: 'horizontal-continuous',
                      child: Text("Horizontal Continuous",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  value: _dropdownValue,
                  onChanged: (value) {
                    if (value != null) {
                      if (value != _dropdownValue) {
                        setState(() {
                          _dropdownValue = value;
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
