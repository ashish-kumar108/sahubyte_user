import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/utils/indian_states.dart';
import 'package:sahubyte_user/view_model/profile_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddAddressView extends StatefulWidget {
  const AddAddressView({super.key, this.userId});

  final String? userId;

  @override
  State<AddAddressView> createState() => _AddAddressViewState();
}

class _AddAddressViewState extends State<AddAddressView> {
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _buildingController = TextEditingController();
  final _streetController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _profileViewModel = ProfileViewModel();
  String? _selectedState;
  bool _isFetchingLocation = false;
  bool _isSavingAddress = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _buildingController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _pinCodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Please turn on device location services.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Enable location permission from app settings.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final address = await _reverseGeocode(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;
      _fillAddress(address);
      _message(
        'Current location fetched. Please confirm details.',
        success: true,
      );
    } catch (error) {
      if (mounted) {
        _message(
          professionalErrorMessage(
            error,
            fallback: 'Location could not be detected. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<Map<String, dynamic>> _reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    var nativeHouse = '';
    if (!kIsWeb) {
      try {
        final placemarks = await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          nativeHouse = [place.subThoroughfare, place.name]
              .whereType<String>()
              .map((value) => value.trim())
              .where((value) {
                return value.isNotEmpty;
              })
              .toSet()
              .join(', ');
        }
      } catch (_) {}
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'zoom': '18',
      'addressdetails': '1',
      'extratags': '1',
      'namedetails': '1',
    });
    final headers = <String, String>{
      'Accept': 'application/json',
      'Accept-Language': 'en',
      if (!kIsWeb) 'User-Agent': 'SahubyteUserApp/1.0',
    };
    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Could not fetch address from GPS.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (nativeHouse.isNotEmpty) {
      data['nativeHouse'] = nativeHouse;
    }
    return data;
  }

  void _fillAddress(Map<String, dynamic> response) {
    final address = Map<String, dynamic>.from(
      response['address'] as Map? ?? {},
    );
    final displayName = response['display_name']?.toString() ?? '';
    final nativeHouse = response['nativeHouse']?.toString().trim() ?? '';

    String pick(List<String> keys) {
      for (final key in keys) {
        final value = address[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    String buildingFromDisplayName() {
      final road = pick(['road', 'pedestrian', 'footway']).toLowerCase();
      final parts = displayName
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
      for (final part in parts.take(4)) {
        final lower = part.toLowerCase();
        final hasBuildingPattern = RegExp(
          r'([a-z]\s*\d+\/\d+)|(\d+\/\d+)|([a-z]-?\d+)|(\b\d+[a-z]?\b)',
          caseSensitive: false,
        ).hasMatch(part);
        final looksLikeRoad =
            lower.contains('road') ||
            lower.contains('street') ||
            lower.contains('marg') ||
            lower.contains('sector') ||
            (road.isNotEmpty && lower == road);
        if (hasBuildingPattern && !looksLikeRoad) return part;
      }
      return '';
    }

    final building = pick([
      'house_name',
      'house_number',
      'building',
      'amenity',
      'shop',
      'office',
      'block',
      'apartments',
      'residential',
    ]);
    _buildingController.text = nativeHouse.isNotEmpty
        ? nativeHouse
        : (building.isNotEmpty ? building : buildingFromDisplayName());
    _streetController.text = pick(['road', 'pedestrian', 'footway']);
    _areaController.text = pick([
      'neighbourhood',
      'suburb',
      'quarter',
      'city_district',
      'county',
    ]);
    _cityController.text = pick(['city', 'town', 'village', 'municipality']);
    _selectedState = matchIndianState(
      pick(['state', 'state_district', 'region']),
    );
    _pinCodeController.text = pick(['postcode']);
    if (_landmarkController.text.trim().isEmpty) {
      _landmarkController.text = pick(['amenity', 'shop', 'office']);
    }
  }

  void _message(String text, {bool success = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        duration: const Duration(milliseconds: 1400),
        backgroundColor: success ? AppColors.navyDark : AppColors.coral,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                success
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _fullAddress {
    return [
          _buildingController.text,
          _streetController.text,
          _areaController.text,
          _cityController.text,
          _pinCodeController.text.isEmpty ? '' : '- ${_pinCodeController.text}',
          _landmarkController.text.isEmpty
              ? ''
              : 'Landmark: ${_landmarkController.text}',
        ]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && value != '-')
        .join(', ');
  }

  Future<String> _resolveUserId() async {
    if (widget.userId?.isNotEmpty == true) return widget.userId!;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id') ??
        prefs.getString('userId') ??
        prefs.getString('id') ??
        '';
  }

  Future<void> _saveAddress() async {
    final address = _fullAddress;
    if (address.trim().isEmpty) {
      _message('Please enter address details first.');
      return;
    }
    if (_isSavingAddress) return;
    setState(() => _isSavingAddress = true);

    try {
      final userId = await _resolveUserId();
      if (userId.isEmpty) {
        _message('Login required to save address.');
        return;
      }
      final response = await _profileViewModel.saveUserAddress(
        act: 'add',
        userId: userId,
        address: address,
        state: _selectedState,
        createdAt: DateTime.now().toIso8601String(),
      );
      if (!mounted) return;
      final responseText = response.displayMessage.trim().toLowerCase();
      final addressWasSaved =
          response.isSuccess ||
          responseText == 'added' ||
          responseText.contains('added') ||
          responseText.contains('saved') ||
          responseText.contains('success');
      if (!addressWasSaved) {
        _message(response.displayMessage);
        return;
      }
      Navigator.pop(context, address);
    } catch (error) {
      if (mounted) {
        _message('Could not save address. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSavingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const AppPageHeader(title: 'Add address'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.only(
            bottom: 24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: appGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x202E245F),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    _CompactHeroIcon(),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add visit address',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'GPS can fill city, street, area and pincode.',
                            style: TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 11,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'STEP 5/8',
                      style: TextStyle(
                        color: AppColors.aqua,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionTitle(
                        'Contact and location',
                        subtitle:
                            'Keep the address complete for faster visits.',
                      ),
                      const SizedBox(height: 18),
                      const AppFieldLabel('Full name'),
                      _buildTextField(
                        controller: _fullNameController,
                        hint: 'Enter full name',
                      ),
                      const SizedBox(height: 14),
                      const AppFieldLabel('Mobile number'),
                      _buildTextField(
                        controller: _mobileController,
                        hint: 'Enter mobile number',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      const AppFieldLabel('House no. / Building / Flat'),
                      _buildTextField(
                        controller: _buildingController,
                        hint: 'House no., building or flat',
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppFieldLabel('Street name'),
                                _buildTextField(
                                  controller: _streetController,
                                  hint: 'Street name',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppFieldLabel('Area name'),
                                _buildTextField(
                                  controller: _areaController,
                                  hint: 'Area name',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppFieldLabel('City'),
                                _buildTextField(
                                  controller: _cityController,
                                  hint: 'City',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppFieldLabel('Pin code'),
                                _buildTextField(
                                  controller: _pinCodeController,
                                  hint: 'Pin code',
                                  keyboardType: TextInputType.number,
                                  suffixIcon: _buildGpsButton(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const AppFieldLabel('State'),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedState,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          hintText: 'Select state',
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                        items: indianStates
                            .map(
                              (state) => DropdownMenuItem(
                                value: state,
                                child: Text(
                                  state,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedState = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      const AppFieldLabel('Nearest landmark'),
                      _buildTextField(
                        controller: _landmarkController,
                        hint: 'Nearby landmark',
                      ),
                      const SizedBox(height: 22),
                      AppPrimaryButton(
                        label: _isSavingAddress
                            ? 'Saving address...'
                            : 'Save address',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _isSavingAddress ? null : _saveAddress,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGpsButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          onPressed: _isFetchingLocation ? null : _detectLocation,
          icon: _isFetchingLocation
              ? const SkeletonBox(width: 18, height: 18, radius: 6)
              : const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
          tooltip: 'Fetch current location',
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(hintText: hint, suffixIcon: suffixIcon),
    );
  }
}

class _CompactHeroIcon extends StatelessWidget {
  const _CompactHeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(
        Icons.add_location_alt_outlined,
        color: AppColors.aqua,
        size: 20,
      ),
    );
  }
}
