import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/api_config.dart';
import '../../services/auth_session.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialBirthday,
    required this.initialGender,
    required this.initialLocation,
    this.initialProfilePictureUrl,
    required this.initialInterests,
  });

  final String initialName;
  final String initialBirthday;
  final String initialGender;
  final String initialLocation;
  final String? initialProfilePictureUrl;
  final List<String> initialInterests;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const String _googlePlacesApiKey =
      'AIzaSyBC5tMGFVQ8yfUJxv9xsRf8VZgJPElr7G4';

  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late List<TextEditingController> _interestControllers;
  late DateTime _selectedBirthday;
  late String _selectedGender;
  String? _profilePictureUrl;
  Uint8List? _pickedProfileImageBytes;
  bool _isPickingImage = false;
  final ImagePicker _imagePicker = ImagePicker();

  Timer? _locationDebounce;
  bool _isLocationLoading = false;
  String? _locationErrorText;
  List<String> _locationSuggestions = [];
  int _locationRequestCounter = 0;
  bool _hasLocationInputChanged = false;

  final List<String> _locations = [
    'Tangerang Selatan',
    'Jakarta Selatan',
    'Jakarta Pusat',
    'Jakarta Barat',
    'Jakarta Timur',
    'Jakarta Utara',
    'Depok',
    'Bekasi',
    'Bogor',
    'Bandung',
    'Surabaya',
    'Yogyakarta',
    'Medan',
    'Makassar',
  ];

  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _locationController = TextEditingController(text: widget.initialLocation);
    _selectedGender = _normalizeGenderForApi(widget.initialGender.trim());
    if (_selectedGender != 'male' && _selectedGender != 'female') {
      _selectedGender = 'male';
    }
    _selectedBirthday = _parseBirthday(widget.initialBirthday);
    _interestControllers = widget.initialInterests
        .map((interest) => TextEditingController(text: interest))
        .toList();
    _profilePictureUrl =
        _resolveProfilePictureUrl(widget.initialProfilePictureUrl);
    _locationSuggestions =
        _getLocalLocationSuggestions(_locationController.text);
  }

  @override
  void dispose() {
    _locationDebounce?.cancel();
    _nameController.dispose();
    _locationController.dispose();
    for (var controller in _interestControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradient.background),
      child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            title: Text(
              'Edit Profile',
                style: AppTextStyles.heading.copyWith(color: Colors.black),
            ),
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE0E0E0),
                          ),
                          child: ClipOval(
                            child: _buildProfileImage(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _isPickingImage
                              ? null
                              : _handleChangeProfilePictureTap,
                          child: const Text(
                            'Change Profile Picture',
                            style: TextStyle(
                              color: Color(0xFF448AFF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Name Field
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFF83D8D),
                              width: 2,
                            ),
                          ),
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Full Name',
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 5),
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Birthday Field
                        _buildBirthdayField(),
                        const SizedBox(height: 10),

                        // Gender Field
                        _buildGenderField(),
                        const SizedBox(height: 10),

                        // Location Field
                        _buildLocationField(),
                        const SizedBox(height: 10),
                        if (_locationErrorText != null) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 100),
                              child: Text(
                                _locationErrorText!,
                                style: const TextStyle(
                                  color: Color(0xFF8B0000),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_hasLocationInputChanged &&
                            _locationSuggestions.isNotEmpty) ...[
                          _buildLocationSuggestionsCard(),
                          const SizedBox(height: 10),
                        ],

                        // Interests Section

                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 100,
                              child: Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text(
                                  'My interests',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF202020),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: _interestControllers
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  int index = entry.key;
                                  TextEditingController controller =
                                      entry.value;
                                  return Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFF448AFF),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: controller,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    vertical: 5),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      if (index <
                                          _interestControllers.length - 1)
                                        const SizedBox(height: 8),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_saveError != null) ...[
                          Text(
                            _saveError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF8B0000),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Done Button
                        SizedBox(
                          width: 200,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _savProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF83D8D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Done',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
    );
  }

  String? _resolveProfilePictureUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) {
      return null;
    }

    final normalizedRaw = rawUrl.replaceAll('\\', '/').trim();
    if (normalizedRaw.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(normalizedRaw);
    final apiBase = Uri.parse(ApiConfig.baseUrl);

    if (parsed != null && parsed.hasScheme) {
      final isLocalHost =
          parsed.host == '127.0.0.1' || parsed.host == 'localhost';
      if (isLocalHost && apiBase.host != parsed.host) {
        return apiBase
            .replace(
              path: parsed.path,
              query: parsed.query,
              fragment: parsed.fragment,
            )
            .toString();
      }
      return normalizedRaw;
    }

    final base = Uri.parse('${ApiConfig.baseUrl}/');
    final withMediaPrefix =
        normalizedRaw.startsWith('/') ? normalizedRaw : '/media/$normalizedRaw';
    return base.resolve(withMediaPrefix).toString();
  }

  Widget _buildProfileImage() {
    if (_pickedProfileImageBytes != null) {
      return Image.memory(_pickedProfileImageBytes!, fit: BoxFit.cover);
    }

    if (_profilePictureUrl == null || _profilePictureUrl!.isEmpty) {
      return Image.asset('assets/FallBackProfile.png', fit: BoxFit.cover);
    }

    return Image.network(
      _profilePictureUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Image.asset('assets/FallBackProfile.png', fit: BoxFit.cover);
      },
    );
  }

  Widget _buildLocationField() {
    return Row(
      children: [
        const SizedBox(
          width: 100,
          child: Text(
            'Location',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF202020),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF448AFF),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _locationController,
              onChanged: _onLocationChanged,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 7),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 16,
                  color: Color(0xFF448AFF),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minHeight: 18,
                  minWidth: 24,
                ),
                suffixIcon: _isLocationLoading
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.8),
                        ),
                      )
                    : (_locationController.text.trim().isEmpty
                        ? null
                        : IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.close,
                              size: 14,
                              color: Color(0xFF448AFF),
                            ),
                            splashRadius: 14,
                            onPressed: () {
                              setState(() {
                                _locationController.clear();
                                _hasLocationInputChanged = true;
                                _locationErrorText = null;
                                _locationSuggestions =
                                    _getLocalLocationSuggestions('');
                              });
                            },
                          )),
              ),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSuggestionsCard() {
    return Padding(
      padding: const EdgeInsets.only(left: 100),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 170),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF448AFF),
              width: 1.2,
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _locationSuggestions.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.black.withValues(alpha: 0.08),
            ),
            itemBuilder: (context, index) {
              final suggestion = _locationSuggestions[index];
              return ListTile(
                dense: true,
                title: Text(
                  suggestion,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
                onTap: () => _selectLocationSuggestion(suggestion),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onLocationChanged(String value) {
    setState(() {
      _hasLocationInputChanged = true;
    });

    _locationDebounce?.cancel();

    _locationDebounce = Timer(const Duration(milliseconds: 350), () {
      final query = value.trim();
      final requestId = ++_locationRequestCounter;

      if (query.length < 2) {
        setState(() {
          _isLocationLoading = false;
          _locationErrorText = null;
          _locationSuggestions = _getLocalLocationSuggestions(query);
        });
        return;
      }

      _fetchLocationSuggestions(query, requestId);
    });
  }

  List<String> _getLocalLocationSuggestions(String query) {
    if (query.isEmpty) {
      return _locations.take(6).toList();
    }

    final lowerQuery = query.toLowerCase();
    return _locations
        .where((city) => city.toLowerCase().contains(lowerQuery))
        .take(8)
        .toList();
  }

  Future<void> _fetchLocationSuggestions(String query, int requestId) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLocationLoading = true;
      _locationErrorText = null;
    });

    if (_googlePlacesApiKey.isEmpty) {
      if (!mounted || requestId != _locationRequestCounter) {
        return;
      }
      setState(() {
        _isLocationLoading = false;
        _locationErrorText =
            'API key not configured. Showing local city suggestions only.';
        _locationSuggestions = _getLocalLocationSuggestions(query);
      });
      return;
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': query,
        'types': '(cities)',
        'key': _googlePlacesApiKey,
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (!mounted || requestId != _locationRequestCounter) {
        return;
      }

      if (response.statusCode != 200) {
        setState(() {
          _isLocationLoading = false;
          _locationErrorText = 'Unable to load suggestions right now.';
          _locationSuggestions = _getLocalLocationSuggestions(query);
        });
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status == 'OK') {
        final predictions = (data['predictions'] as List<dynamic>)
            .map(
              (item) => (item as Map<String, dynamic>)['description'] as String,
            )
            .toList();

        setState(() {
          _isLocationLoading = false;
          _locationSuggestions = predictions;
        });
      } else if (status == 'ZERO_RESULTS') {
        setState(() {
          _isLocationLoading = false;
          _locationSuggestions = [];
        });
      } else {
        setState(() {
          _isLocationLoading = false;
          _locationErrorText = 'Location service unavailable ($status).';
          _locationSuggestions = _getLocalLocationSuggestions(query);
        });
      }
    } catch (_) {
      if (!mounted || requestId != _locationRequestCounter) {
        return;
      }
      setState(() {
        _isLocationLoading = false;
        _locationErrorText =
            'Network issue while searching. Showing local suggestions.';
        _locationSuggestions = _getLocalLocationSuggestions(query);
      });
    }
  }

  void _selectLocationSuggestion(String value) {
    setState(() {
      _locationController.text = value;
      _hasLocationInputChanged = false;
      _locationSuggestions = [];
      _locationErrorText = null;
    });

    FocusScope.of(context).unfocus();
  }

  Widget _buildBirthdayField() {
    return Row(
      children: [
        const SizedBox(
          width: 100,
          child: Text(
            'Birthday date',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF202020),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: _openBirthdayPicker,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF448AFF),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatBirthday(_selectedBirthday),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: Color(0xFF448AFF),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return Row(
      children: [
        const SizedBox(
          width: 100,
          child: Text(
            'Gender',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF202020),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF448AFF),
                width: 1.5,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGender,
                isExpanded: true,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black,
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedGender = value;
                        });
                      },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openBirthdayPicker() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        DateTime tempDate = _selectedBirthday;
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () {
                        setState(() => _selectedBirthday = tempDate);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedBirthday,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (DateTime date) {
                    tempDate = date;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  DateTime _parseBirthday(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
    return DateTime(2002, 5, 8);
  }

  String _formatBirthday(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<void> _handleChangeProfilePictureTap() async {
    if (_isPickingImage) {
      return;
    }

    setState(() {
      _isPickingImage = true;
    });

    try {
      final hasPermission = await _ensureGalleryPermission();
      if (!hasPermission || !mounted) {
        return;
      }

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1440,
      );

      if (pickedFile == null || !mounted) {
        return;
      }

      final pickedBytes = await pickedFile.readAsBytes();

      if (!mounted) {
        return;
      }

      setState(() {
        _pickedProfileImageBytes = pickedBytes;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      await _showGalleryPermissionSettingsDialog();
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<bool> _ensureGalleryPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      var photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return true;
      }
      if (photosStatus.isDenied || photosStatus.isRestricted) {
        photosStatus = await Permission.photos.request();
      }
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return true;
      }

      var storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) {
        return true;
      }
      if (storageStatus.isDenied || storageStatus.isRestricted) {
        storageStatus = await Permission.storage.request();
      }
      if (storageStatus.isGranted) {
        return true;
      }

      return _showGalleryPermissionSettingsDialog();
    }

    var status = await Permission.photos.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }
    if (status.isDenied || status.isRestricted) {
      status = await Permission.photos.request();
    }
    if (status.isGranted || status.isLimited) {
      return true;
    }

    return _showGalleryPermissionSettingsDialog();
  }

  Future<bool> _showGalleryPermissionSettingsDialog() async {
    if (!mounted) {
      return false;
    }

    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Gallery Permission Needed'),
          content: const Text(
            'Please allow gallery access so you can choose a profile picture.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );

    if (shouldOpenSettings == true) {
      try {
        await openAppSettings();
      } on MissingPluginException {
        if (!mounted) {
          return false;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Open Settings is unavailable right now. Please fully restart the app and try again.',
            ),
          ),
        );
      }
    }

    return false;
  }

  Future<void> _savProfile() async {
    if (_isSaving) {
      return;
    }

    final userId = AuthSession.instance.userId;
    if (userId == null) {
      setState(() {
        _saveError = 'No logged-in user found.';
      });
      return;
    }

    final interests = _interestControllers
        .map((c) => c.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    String interestAt(int index) {
      if (index < interests.length) {
        return interests[index];
      }
      return '';
    }

    final payload = <String, String>{
      'name': _nameController.text.trim(),
      'birthday': _formatBirthday(_selectedBirthday),
      'gender': _selectedGender,
      'location': _locationController.text.trim(),
      'intrest1': interestAt(0),
      'intrest2': interestAt(1),
      'intrest3': interestAt(2),
      'intrest4': interestAt(3),
    };

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/$userId/edit-user/');

    try {
      http.Response response;

      if (_pickedProfileImageBytes != null) {
        final request = http.MultipartRequest('PATCH', uri)
          ..fields.addAll(payload)
          ..files.add(
            http.MultipartFile.fromBytes(
              'profilepicture',
              _pickedProfileImageBytes!,
              filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          );

        final streamed = await request.send().timeout(
              const Duration(seconds: 12),
            );
        response = await http.Response.fromStream(streamed);
      } else {
        response = await http
            .patch(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 12));
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isSaving = false;
          _saveError =
              'Save failed (${response.statusCode}): ${_extractBackendError(response.body)}';
        });
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isSaving = false;
          _saveError = 'Invalid profile response from server.';
        });
        return;
      }

      await AuthSession.instance.saveUser(decoded);

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _profilePictureUrl = _resolveProfilePictureUrl(
          decoded['profilepicture'] as String?,
        );
        _pickedProfileImageBytes = null;
      });

      Navigator.of(context).pop(decoded);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _saveError =
            'Cannot connect to backend. Ensure Django is running on ${ApiConfig.baseUrl}.';
      });
    }
  }

  String _normalizeGenderForApi(String value) {
    final lower = value.toLowerCase();
    switch (lower) {
      case 'male':
      case 'man':
        return 'male';
      case 'female':
      case 'woman':
        return 'female';
      default:
        return value;
    }
  }

  String _extractBackendError(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded;
      }

      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail;
        }

        if (decoded.isNotEmpty) {
          final firstValue = decoded.values.first;
          if (firstValue is List && firstValue.isNotEmpty) {
            return firstValue.first.toString();
          }
          return firstValue.toString();
        }
      }
    } catch (_) {
      // Keep fallback below.
    }

    final trimmed = responseBody.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }

    return 'Please check your input.';
  }
}
