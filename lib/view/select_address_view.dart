import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:sahubyte_user/model/response/user_address_model.dart';
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/view/add_address_view.dart';
import 'package:sahubyte_user/view/select_date_time_view.dart';
import 'package:sahubyte_user/view_model/profile_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectAddressView extends StatefulWidget {
  const SelectAddressView({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.subCategoryId,
    required this.subCategoryName,
    required this.brandId,
    required this.brandName,
    required this.problemIds,
    this.problemDetails = const [],
    this.problemTitle = 'Service diagnosis',
    this.problemCharge = 0,
    this.serviceType = 'Software',
  });

  final String categoryId;
  final String categoryName;
  final String subCategoryId;
  final String subCategoryName;
  final String brandId;
  final String brandName;
  final List<String> problemIds;
  final List<Map<String, dynamic>> problemDetails;
  final String problemTitle;
  final int problemCharge;
  final String serviceType;

  @override
  State<SelectAddressView> createState() => _SelectAddressViewState();
}

class _SelectAddressViewState extends State<SelectAddressView> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  Timer? _mapMoveDebounce;
  List<Map<String, dynamic>> _searchResults = [];
  String _fetchedAddress =
      'D1/37, Pocket 1, Sector 16D, Rohini, Delhi, 110089, India';
  double _latitude = 28.7041;
  double _longitude = 77.1025;
  bool _isFetchingLocation = false;
  bool _isSearching = false;
  bool _isLoadingSavedAddresses = true;
  bool _currentLocationSelected = true;
  bool _showSavedAddressDropdown = false;
  String _userId = '';
  String? _selectedSavedAddressId;
  List<UserAddressModel> _savedAddresses = [];
  final _profileViewModel = ProfileViewModel();
  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation(showError: false);
    _loadSavedAddresses();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _mapMoveDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAddresses({String? preferredAddress}) async {
    final prefs = await SharedPreferences.getInstance();
    final userId =
        prefs.getString('user_id') ??
        prefs.getString('userId') ??
        prefs.getString('id') ??
        '';
    if (!mounted) return;
    setState(() {
      _userId = userId;
      _isLoadingSavedAddresses = userId.isNotEmpty;
    });
    if (userId.isEmpty) return;
    try {
      final addresses = await _profileViewModel.getUserAddresses(userId);
      if (!mounted) return;
      UserAddressModel? selectedAddress;
      if (preferredAddress?.trim().isNotEmpty == true) {
        for (final address in addresses) {
          if (address.address.trim() == preferredAddress!.trim()) {
            selectedAddress = address;
            break;
          }
        }
        selectedAddress ??= _latestAddress(addresses);
      } else {
        selectedAddress = addresses.isEmpty ? null : addresses.first;
      }
      setState(() {
        _savedAddresses = addresses;
        _selectedSavedAddressId =
            selectedAddress?.id ?? _selectedSavedAddressId;
        if (selectedAddress != null &&
            (preferredAddress != null || !_currentLocationSelected)) {
          _fetchedAddress = selectedAddress.address;
          _currentLocationSelected = preferredAddress == null
              ? _currentLocationSelected
              : false;
        }
        _isLoadingSavedAddresses = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingSavedAddresses = false);
    }
  }

  UserAddressModel? _latestAddress(List<UserAddressModel> addresses) {
    if (addresses.isEmpty) return null;
    return addresses.reduce((latest, current) {
      final latestId = int.tryParse(latest.id) ?? -1;
      final currentId = int.tryParse(current.id) ?? -1;
      return currentId >= latestId ? current : latest;
    });
  }

  void _onMapMoved(LatLng center) {
    setState(() {
      _latitude = center.latitude;
      _longitude = center.longitude;
    });
    _mapMoveDebounce?.cancel();
    _mapMoveDebounce = Timer(const Duration(milliseconds: 650), () async {
      try {
        final location = await _reverseGeocode(
          center.latitude,
          center.longitude,
        );
        if (!mounted) return;
        setState(() {
          _fetchedAddress = location.address;
        });
      } catch (_) {
        // Keep last known address if reverse lookup fails while dragging.
      }
    });
  }

  Future<void> _fetchCurrentLocation({bool showError = true}) async {
    if (_isFetchingLocation) return;
    setState(() {
      _isFetchingLocation = true;
      _searchResults = [];
    });

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
      final location = await _reverseGeocode(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _fetchedAddress = location.address;
      });
      _mapController.move(LatLng(_latitude, _longitude), 16.2);
    } catch (error) {
      if (showError && mounted) {
        _message(
          professionalErrorMessage(
            error,
            fallback: 'Location could not be refreshed. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<_ResolvedLocation> _reverseGeocode(
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
      } catch (_) {
        // Nominatim fallback below still provides the full address.
      }
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
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final address = Map<String, dynamic>.from(json['address'] as Map? ?? {});
    final displayName = json['display_name']?.toString().trim() ?? '';

    String pick(List<String> keys) {
      for (final key in keys) {
        final value = address[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    final houseNumber = pick(['house_number']);
    final building = pick([
      'house_name',
      'building',
      'amenity',
      'shop',
      'office',
      'residential',
    ]);
    final road = pick(['road', 'pedestrian', 'footway']);
    final suburb = pick(['suburb', 'neighbourhood', 'quarter', 'locality']);
    final city = pick(['city', 'town', 'village', 'county']);
    final district = pick(['state_district', 'city_district']);
    final postcode = pick(['postcode']);

    final parts = <String>[];
    for (final value in [
      nativeHouse,
      building,
      houseNumber,
      road,
      suburb,
      city,
      district,
      postcode,
    ]) {
      if (value.isNotEmpty && !parts.contains(value)) parts.add(value);
    }

    if (nativeHouse.isNotEmpty && !displayName.contains(nativeHouse)) {
      return _ResolvedLocation(
        address: [
          nativeHouse,
          displayName,
        ].where((value) => value.isNotEmpty).join(', '),
      );
    }
    return _ResolvedLocation(
      address: displayName.isNotEmpty
          ? displayName
          : (parts.isNotEmpty ? parts.join(', ') : _fetchedAddress),
    );
  }

  void _searchLocation(String query) {
    _searchDebounce?.cancel();
    final value = query.trim();
    if (value.length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _performSearch(value),
    );
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2',
        'q': query,
        'limit': '5',
        'addressdetails': '1',
      });
      final headers = <String, String>{
        'Accept': 'application/json',
        if (!kIsWeb) 'User-Agent': 'SahubyteUserApp/1.0',
      };
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body);
      if (!mounted || data is! List) return;
      setState(() {
        _searchResults = data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final address = result['display_name']?.toString() ?? '';
    if (address.isEmpty) return;
    final lat = double.tryParse(result['lat']?.toString() ?? '');
    final lon = double.tryParse(result['lon']?.toString() ?? '');
    setState(() {
      _fetchedAddress = address;
      _currentLocationSelected = true;
      if (lat != null && lon != null) {
        _latitude = lat;
        _longitude = lon;
      }
      _searchController.clear();
      _searchResults = [];
    });
    if (lat != null && lon != null) {
      _mapController.move(LatLng(lat, lon), 16.2);
    }
  }

  void _confirmLocation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectDateTimeView(
          categoryId: widget.categoryId,
          categoryName: widget.categoryName,
          subCategoryId: widget.subCategoryId,
          subCategoryName: widget.subCategoryName,
          brandId: widget.brandId,
          brandName: widget.brandName,
          problemIds: widget.problemIds,
          problemDetails: widget.problemDetails,
          address: _selectedVisitAddress,
          problemTitle: widget.problemTitle,
          problemCharge: widget.problemCharge,
          serviceType: widget.serviceType,
        ),
      ),
    );
  }

  String get _selectedVisitAddress {
    if (_currentLocationSelected) return _fetchedAddress;
    for (final address in _savedAddresses) {
      if (address.id == _selectedSavedAddressId) return address.address;
    }
    return _fetchedAddress;
  }

  void _message(String text, {bool success = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        duration: const Duration(milliseconds: 1500),
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
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _shortArea {
    final parts = _fetchedAddress
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 4) return parts[2];
    if (parts.length >= 2) return parts[1];
    return parts.isNotEmpty ? parts.first : 'Rohini';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppPageHeader(title: 'Select address'),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              gradient: appGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x202E245F),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0x22FFFFFF),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    color: AppColors.aqua,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Confirm visit location',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0x1FFFFFFF),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: const Text(
                    'STEP 5/8',
                    style: TextStyle(
                      color: AppColors.aqua,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  _loadSavedAddresses(),
                  _fetchCurrentLocation(showError: false),
                ]);
              },
              child: LayoutBuilder(
                builder: (context, viewport) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 7, 16, 8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final widthBasedHeight = constraints.maxWidth * 1.18;
                        final reservedHeight = _showSavedAddressDropdown
                            ? 300.0
                            : 230.0;
                        final availableHeight =
                            viewport.maxHeight - reservedHeight;
                        final fittedHeight = widthBasedHeight < availableHeight
                            ? widthBasedHeight
                            : availableHeight;
                        final mapHeight = fittedHeight
                            .clamp(260.0, 500.0)
                            .toDouble();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMapCard(height: mapHeight),
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Pickup address',
                                    style: TextStyle(
                                      color: AppColors.text,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Saved addresses',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _AddressChoiceTile(
                              icon: Icons.my_location_rounded,
                              title: 'Current location',
                              badge: 'GPS',
                              address: _isFetchingLocation
                                  ? 'Detecting your current address...'
                                  : _fetchedAddress,
                              selected: _currentLocationSelected,
                              onTap: () => setState(() {
                                _currentLocationSelected = true;
                              }),
                            ),
                            const SizedBox(height: 6),
                            _buildSavedAddressSelector(),
                            const SizedBox(height: 4),
                            Center(
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () async {
                                  final address = await Navigator.push<String>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddAddressView(userId: _userId),
                                    ),
                                  );
                                  if (!mounted || address == null) return;
                                  setState(() {
                                    _fetchedAddress = address;
                                    _currentLocationSelected = false;
                                    _showSavedAddressDropdown = true;
                                  });
                                  await _loadSavedAddresses(
                                    preferredAddress: address,
                                  );
                                  if (!mounted) return;
                                  _message(
                                    'Address added successfully.',
                                    success: true,
                                  );
                                },
                                icon: const Icon(
                                  Icons.add_location_alt_outlined,
                                ),
                                label: const Text('Add address manually'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          AppBottomAction(
            label: 'Confirm & continue',
            onPressed: _isFetchingLocation ? null : _confirmLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAddressSelector() {
    if (_isLoadingSavedAddresses) {
      return const AppSurfaceCard(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            SkeletonBox(width: 44, height: 44, radius: 15),
            SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 120, height: 14, radius: 6),
                  SizedBox(height: 8),
                  SkeletonBox(width: double.infinity, height: 11, radius: 5),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (_savedAddresses.isEmpty) {
      return _AddressChoiceTile(
        icon: Icons.home_work_rounded,
        title: 'No saved address',
        address: 'Add address manually to save one.',
        selected: false,
      );
    }

    final selected = _savedAddresses.firstWhere(
      (address) => address.id == _selectedSavedAddressId,
      orElse: () => _savedAddresses.first,
    );
    final isSelected = !_currentLocationSelected;
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _currentLocationSelected = false;
              _showSavedAddressDropdown = !_showSavedAddressDropdown;
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF8FAFF) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: .22)
                    : AppColors.line,
                width: isSelected ? 1.4 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F0A1022),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.home_work_rounded,
                    color: AppColors.primary,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Saved address',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.navyDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_savedAddresses.length}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        selected.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _showSavedAddressDropdown ? .5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                    size: 25,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showSavedAddressDropdown) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 82),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120A1022),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: _savedAddresses.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final address = _savedAddresses[index];
                final selected = address.id == _selectedSavedAddressId;
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.location_on_outlined,
                    color: selected ? AppColors.primary : AppColors.muted,
                  ),
                  title: Text(
                    address.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedSavedAddressId = address.id;
                      _fetchedAddress = address.address;
                      _currentLocationSelected = false;
                      _showSavedAddressDropdown = false;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMapCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x160A1022),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_latitude, _longitude),
                initialZoom: 15,
                minZoom: 4,
                maxZoom: 19,
                onPositionChanged: (position, hasGesture) {
                  if (!hasGesture) return;
                  _onMapMoved(position.center);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sahubyte.user',
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: .10),
                      Colors.transparent,
                      AppColors.navyDark.withValues(alpha: .08),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Column(
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x180A1022),
                        blurRadius: 14,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchLocation,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search area, street or landmark',
                      hintStyle: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                      prefixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: SkeletonBox(
                                  width: 18,
                                  height: 18,
                                  radius: 6,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                            ),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 160),
                    decoration: appSurface(radius: 18),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            result['display_name']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Center(
            child: Transform.translate(
              offset: const Offset(0, -18),
              child: const Icon(
                Icons.location_pin,
                color: AppColors.primary,
                size: 64,
                shadows: [Shadow(color: Colors.white, blurRadius: 12)],
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x260A1022),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _isFetchingLocation
                    ? null
                    : () => _fetchCurrentLocation(),
                icon: _isFetchingLocation
                    ? const SkeletonBox(width: 20, height: 20, radius: 7)
                    : const Icon(
                        Icons.my_location_rounded,
                        color: AppColors.primary,
                      ),
                tooltip: 'Detect Location',
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.navyDark.withValues(alpha: .88),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.aqua,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _shortArea,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressChoiceTile extends StatelessWidget {
  const _AddressChoiceTile({
    required this.icon,
    required this.title,
    required this.address,
    required this.selected,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String address;
  final bool selected;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF8FAFF) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: .22)
                  : AppColors.line,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F0A1022),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.primary, size: 25),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.navyDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.primary : AppColors.line,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResolvedLocation {
  const _ResolvedLocation({required this.address});

  final String address;
}
