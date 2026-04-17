import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';

class CityDropdown extends StatefulWidget {
  final String? selectedCity;
  final Function(String)? onChanged;
  final bool enabled;

  const CityDropdown({
    super.key,
    this.selectedCity,
    this.onChanged,
    this.enabled = true,
  });

  @override
  _CityDropdownState createState() => _CityDropdownState();
}

class _CityDropdownState extends State<CityDropdown> {
  final TextEditingController _controller = TextEditingController();
  List<String> cities = [];
  String? _selectedCity;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.selectedCity;
    if (_selectedCity != null) {
      _controller.text = _selectedCity!;
    }
    _fetchCitiesFromFirestore();
  }

  /// 🔥 Fetch cities list from Firestore
  Future<void> _fetchCitiesFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Cities')
          .doc('all_cities')
          .get();

      if (snapshot.exists) {
        final List<dynamic> cityList = snapshot.data()?['cityList'] ?? [];
        setState(() {
          cities = cityList.cast<String>();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ Error fetching cities: $e");
      setState(() => _isLoading = false);
    }
  }

  void _openDropdownDialog() {
    if (cities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: SmartText(title: "No cities found"),
          backgroundColor: AppColors.red,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        List<String> filteredCities = List.from(cities);
        final searchController = TextEditingController();

        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(top: 60),
              padding: const EdgeInsets.all(8),
              width: MediaQuery.of(context).size.width * 0.95,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
              ),
              child: StatefulBuilder(
                builder: (context, setStateDialog) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: "Search city...",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setStateDialog(() {
                            filteredCities = cities
                                .where(
                                  (c) => c.toLowerCase().contains(
                                    value.toLowerCase(),
                                  ),
                                )
                                .toList();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          itemCount: filteredCities.length,
                          itemBuilder: (context, index) {
                            final city = filteredCities[index];

                            final bool isEven = index % 2 == 0;

                            // Primary orange
                            const Color primaryOrange = Color(0xFFFF901A);

                            // Light orange (20% opacity)
                            final Color lightOrange = primaryOrange.withOpacity(
                              0.15,
                            );

                            return Column(
                              children: [
                                Container(
                                  color: isEven
                                      ? primaryOrange.withOpacity(0.20)
                                      : lightOrange,
                                  child: ListTile(
                                    title: Text(
                                      city,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedCity = city;
                                        _controller.text = city;
                                      });
                                      widget.onChanged?.call(city);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),

                                // Divider
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Colors.black26,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: widget.enabled ? _openDropdownDialog : null,
      child: AbsorbPointer(
        child: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: "Select City",
            prefixIcon: const Icon(Icons.location_city),
            suffixIcon: widget.enabled ? const Icon(Icons.arrow_drop_down) : null,
            filled: true,
            fillColor: widget.enabled ? Colors.grey[200] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          style: TextStyle(
            color: widget.enabled ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
