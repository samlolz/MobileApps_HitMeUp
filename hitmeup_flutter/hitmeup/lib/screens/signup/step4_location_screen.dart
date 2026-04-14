import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../widgets/common_widgets.dart';
import 'step5_meet_gender_screen.dart';

class Step4LocationScreen extends StatefulWidget {
  const Step4LocationScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.gender,
    required this.birthday,
  });

  final String name;
  final String email;
  final String password;
  final String gender;
  final DateTime birthday;

  @override
  State<Step4LocationScreen> createState() => _Step4LocationScreenState();
}

class _Step4LocationScreenState extends State<Step4LocationScreen> {
  static const String _googlePlacesApiKey = 'AIzaSyBC5tMGFVQ8yfUJxv9xsRf8VZgJPElr7G4';

  static const TextStyle _headerTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 25,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.0,
    letterSpacing: 0,
  );

  static const TextStyle _inputTextStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 19,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    height: 1.0,
    letterSpacing: 0,
  );

  static const TextStyle _inputHintTextStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 19,
    fontWeight: FontWeight.w400,
    color: Color.fromRGBO(255, 255, 255, 0.65),
    height: 1.0,
    letterSpacing: 0,
  );

  static const TextStyle _continueButtonTextStyle = TextStyle(
    fontFamily: 'Konkhmer Sleokchher',
    fontSize: 19,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    height: 1.0,
    letterSpacing: 0,
  );

  static const Color _continueButtonColor = Color.fromRGBO(101, 101, 101, 1);

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String _selectedLocation = '';
  List<String> _suggestions = [];
  bool _isLoading = false;
  String? _errorText;
  int _requestCounter = 0;

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

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _selectedLocation = value;
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), () {
      final query = value.trim();
      final requestId = ++_requestCounter;

      if (query.length < 2) {
        setState(() {
          _isLoading = false;
          _errorText = null;
          _suggestions = _getLocalSuggestions(query);
        });
        return;
      }

      _fetchLocationSuggestions(query, requestId);
    });
  }

  List<String> _getLocalSuggestions(String query) {
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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    if (_googlePlacesApiKey.isEmpty) {
      if (!mounted || requestId != _requestCounter) return;
      setState(() {
        _isLoading = false;
        _errorText =
            'API key not configured. Showing local city suggestions only.';
        _suggestions = _getLocalSuggestions(query);
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
      if (!mounted || requestId != _requestCounter) return;

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorText = 'Unable to load suggestions right now.';
          _suggestions = _getLocalSuggestions(query);
        });
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status == 'OK') {
        final predictions = (data['predictions'] as List<dynamic>)
            .map((item) => (item as Map<String, dynamic>)['description'] as String)
            .toList();

        setState(() {
          _isLoading = false;
          _suggestions = predictions;
        });
      } else if (status == 'ZERO_RESULTS') {
        setState(() {
          _isLoading = false;
          _suggestions = [];
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorText = 'Location service unavailable ($status).';
          _suggestions = _getLocalSuggestions(query);
        });
      }
    } catch (_) {
      if (!mounted || requestId != _requestCounter) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Network issue while searching. Showing local suggestions.';
        _suggestions = _getLocalSuggestions(query);
      });
    }
  }

  void _onSelectSuggestion(String value) {
    setState(() {
      _selectedLocation = value;
      _searchController.text = value;
      _suggestions = [];
      _errorText = null;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          SignupAppBar(onBack: () => Navigator.pop(context)),
          Expanded(
            child: GradientBackground(
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(left: 36, right: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Center(
                        child: StepIndicator(totalSteps: 6, currentStep: 3),
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        'Where do you live?',
                        style: _headerTextStyle,
                      ),
                      const SizedBox(height: 32),
                      _buildLocationSearch(),
                      const Spacer(),
                      _buildContinueButton(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSearch() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF6750A4),
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: _inputTextStyle,
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'Search your city',
              hintStyle: _inputHintTextStyle,
              border: InputBorder.none,
              icon: const Icon(Icons.search, color: Colors.white),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : (_searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _selectedLocation = '';
                              _suggestions = _locations.take(6).toList();
                              _errorText = null;
                            });
                          },
                        )),
            ),
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _errorText!,
              style: _inputTextStyle.copyWith(
                fontSize: 12,
                color: const Color(0xFFFFD8D8),
              ),
            ),
          ),
        ],
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4C3F79).withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6750A4), width: 1),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Colors.white.withOpacity(0.12),
                ),
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      suggestion,
                      style: _inputTextStyle.copyWith(color: Colors.white),
                    ),
                    onTap: () => _onSelectSuggestion(suggestion),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 67,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _continueButtonColor,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: _selectedLocation.trim().isEmpty
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Step5MeetGenderScreen(
                      name: widget.name,
                      email: widget.email,
                      password: widget.password,
                      gender: widget.gender,
                      birthday: widget.birthday,
                      location: _selectedLocation.trim(),
                    ),
                  ),
                );
              },
        child: const Text(
          'CONTINUE',
          style: _continueButtonTextStyle,
        ),
      ),
    );
  }
}