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
    required this.initialWantToMeet,
    this.initialProfilePictureUrl,
    required this.initialInterests,
  });

  final String initialName;
  final String initialBirthday;
  final String initialGender;
  final String initialLocation;
  final String initialWantToMeet;
  final String? initialProfilePictureUrl;
  final List<String> initialInterests;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const TextStyle _changeProfilePictureTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.0,
    color: Color.fromRGBO(68, 138, 255, 1),
  );

  static const TextStyle _profileNameTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 17,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.0,
    color: Color(0xFF1F1F1F),
  );

  static const TextStyle _labelTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.0,
    color: Color(0xFF202020),
  );

  static const TextStyle _inputTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.0,
    color: Color.fromRGBO(118, 118, 118, 1),
  );

  static const TextStyle _doneButtonTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 17,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.0,
    color: Colors.white,
  );

  static const String _googlePlacesApiKey =
      'AIzaSyBC5tMGFVQ8yfUJxv9xsRf8VZgJPElr7G4';

  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late List<TextEditingController> _interestControllers;
  late DateTime _selectedBirthday;
  late String _selectedGender;
  late String _selectedWantToMeet;
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
    _selectedWantToMeet = _normalizeWantToMeetForApi(widget.initialWantToMeet);
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
                            color: Color(0xFF448AFF),
                          ),
                          child: ClipOval(
                            child: Container(
                              color: Colors.white,
                              child: _buildProfileImage(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _isPickingImage
                              ? null
                              : _handleChangeProfilePictureTap,
                          child: const Text(
                            'Change Profile Picture',
                            textAlign: TextAlign.center,
                            style: _changeProfilePictureTextStyle,
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
                            style: _profileNameTextStyle,
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
                                  style: _labelTextStyle,
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
                                        height: 32,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFF448AFF),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: controller,
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    vertical: 7),
                                          ),
                                          style: _inputTextStyle,
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
                        const SizedBox(height: 12),
                        _buildWantToMeetField(),
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
                              textStyle: _doneButtonTextStyle,
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
                                    textAlign: TextAlign.center,
                                    style: _doneButtonTextStyle,
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
            style: _labelTextStyle,
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
              style: _inputTextStyle,
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
              color: Colors.black.withOpacity(0.08),
            ),
            itemBuilder: (context, index) {
              final suggestion = _locationSuggestions[index];
              return ListTile(
                dense: true,
                title: Text(
                  suggestion,
                  style: _inputTextStyle.copyWith(color: Colors.black),
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
            style: _labelTextStyle,
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
                      _formatBirthdayForDisplay(_selectedBirthday),
                      style: _inputTextStyle,
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
            style: _labelTextStyle,
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
                style: _inputTextStyle,
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

  Widget _buildWantToMeetField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 100,
          child: Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Who do you want to meet?',
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
            children: [
              _buildWantToMeetOption('man', 'Man'),
              const SizedBox(height: 8),
              _buildWantToMeetOption('woman', 'Woman'),
              const SizedBox(height: 8),
              _buildWantToMeetOption('everyone', 'Everyone'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWantToMeetOption(String value, String label) {
    final isSelected = _selectedWantToMeet == value;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _isSaving
          ? null
          : () {
              setState(() {
                _selectedWantToMeet = value;
              });
            },
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF448AFF),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF448AFF) : Colors.black,
                  width: 1.6,
                ),
                color: isSelected ? const Color(0xFF448AFF) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
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
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return DateTime(2002, 5, 8);
    }

    final datePart = trimmed.contains('T') ? trimmed.split('T').first : trimmed;
    final parsed = DateTime.tryParse(datePart);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    final parts = datePart.split(RegExp(r'\s+'));
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = _monthNumberFromName(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return DateTime(2002, 5, 8);
  }

  int? _monthNumberFromName(String monthName) {
    switch (monthName.toLowerCase()) {
      case 'january':
        return 1;
      case 'february':
        return 2;
      case 'march':
        return 3;
      case 'april':
        return 4;
      case 'may':
        return 5;
      case 'june':
        return 6;
      case 'july':
        return 7;
      case 'august':
        return 8;
      case 'september':
        return 9;
      case 'october':
        return 10;
      case 'november':
        return 11;
      case 'december':
        return 12;
      default:
        return null;
    }
  }

  String _formatBirthdayForDisplay(DateTime value) {
    const monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${value.day} ${monthNames[value.month - 1]} ${value.year}';
  }

  String _formatBirthdayForApi(DateTime value) {
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
      'birthday': _formatBirthdayForApi(_selectedBirthday),
      'gender': _selectedGender,
      'wanttomeet': _selectedWantToMeet,
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

  String _normalizeWantToMeetForApi(String value) {
    final lower = value.toLowerCase().trim();
    switch (lower) {
      case 'man':
      case 'male':
        return 'man';
      case 'woman':
      case 'female':
        return 'woman';
      case 'everyone':
      case 'anyone':
      case 'others':
      case 'other':
        return 'everyone';
      default:
        return 'everyone';
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
