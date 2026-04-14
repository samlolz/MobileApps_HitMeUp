import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_theme.dart';
import 'chat_models.dart';
import 'community_chat_screen.dart';
import '../../services/chat_service.dart';
import '../../services/auth_session.dart';
import 'dart:typed_data';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  static const TextStyle _changePictureTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.0,
    letterSpacing: 0,
    color: Color.fromRGBO(68, 138, 255, 1),
  );

  static const TextStyle _communityNameTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w500,
    fontSize: 17,
    height: 1.0,
    letterSpacing: 0,
    color: AppColors.textDark,
  );

  static const TextStyle _communityNameHintTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w500,
    fontSize: 17,
    height: 1.0,
    letterSpacing: 0,
    color: AppColors.textGrey,
  );

  static const TextStyle _fieldLabelTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w500,
    fontSize: 11,
    height: 1.0,
    letterSpacing: 0,
    color: AppColors.textDark,
  );

  static const TextStyle _fieldInputTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w500,
    fontSize: 11,
    height: 1.0,
    letterSpacing: 0,
    color: Color.fromRGBO(118, 118, 118, 1),
  );

  static const TextStyle _fieldHintTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w500,
    fontSize: 11,
    height: 1.0,
    letterSpacing: 0,
    color: Color.fromRGBO(118, 118, 118, 1),
  );

  static const TextStyle _createButtonTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w500,
    fontSize: 17,
    height: 1.0,
    letterSpacing: 0,
    color: Colors.white,
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _pickedCommunityImageBytes;
  bool _isPickingImage = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 25,
              color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create a new community',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradient.background),
        child: SafeArea(
          top: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _pickedCommunityImageBytes != null
                          ? Image.memory(_pickedCommunityImageBytes!,
                              fit: BoxFit.cover)
                          : const Icon(Icons.person,
                              size: 70, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isPickingImage
                          ? null
                          : _handleChangeCommunityPictureTap,
                      child: const Text(
                        'Change Profile Picture',
                        style: _changePictureTextStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 211,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFFF4081), width: 2),
                      ),
                      child: TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        style: _communityNameTextStyle,
                        decoration: const InputDecoration(
                          hintText: 'Community name',
                          hintStyle: _communityNameHintTextStyle,
                          border: InputBorder.none,
                          isDense: false,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Community description',
                      textAlign: TextAlign.center,
                      style: _fieldLabelTextStyle,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 285,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFF448AFF), width: 1),
                      ),
                      child: TextField(
                        controller: _descController,
                        textAlignVertical: TextAlignVertical.center,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        style: _fieldInputTextStyle,
                        decoration: const InputDecoration(
                          hintText: 'Input description',
                          hintStyle: _fieldHintTextStyle,
                          border: InputBorder.none,
                          isDense: false,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Maximum participants',
                      textAlign: TextAlign.center,
                      style: _fieldLabelTextStyle,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 285,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFF448AFF), width: 1),
                      ),
                      child: TextField(
                        controller: _maxController,
                        textAlignVertical: TextAlignVertical.center,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: _fieldInputTextStyle,
                        decoration: const InputDecoration(
                          hintText: 'Input number',
                          hintStyle: _fieldHintTextStyle,
                          border: InputBorder.none,
                          isDense: false,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 180,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pinkTop,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        onPressed:
                            _isCreating ? null : _handleCreateCommunity,
                        child: _isCreating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Create',
                                style: _createButtonTextStyle,
                                textAlign: TextAlign.center,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleChangeCommunityPictureTap() async {
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
        _pickedCommunityImageBytes = pickedBytes;
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

  Future<void> _handleCreateCommunity() async {
    // Validate inputs
    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    final maxParticipantsStr = _maxController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a community name')),
      );
      return;
    }

    if (maxParticipantsStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter maximum participants')),
      );
      return;
    }

    final maxParticipants = int.tryParse(maxParticipantsStr);
    if (maxParticipants == null || maxParticipants <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Maximum participants must be a valid number greater than 0')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final createdCommunity = await ChatService.createCommunity(
        name: name,
        description: description,
        maxParticipants: maxParticipants,
        communityPictureBytes: _pickedCommunityImageBytes,
        pictureName: _pickedCommunityImageBytes != null
            ? 'community_${DateTime.now().millisecondsSinceEpoch}.jpg'
            : null,
      );

      if (!mounted) return;

      final communityId = createdCommunity['id'];

      final userId = AuthSession.instance.userId;
      if (userId != null) {
        try {
          await ChatService.addUserToCommunity(
            userId: userId,
            communityId: communityId,
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Warning: Could not add you as a member: ${e.toString()}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      final community = Community(
        id: communityId.toString(),
        name: name,
        participants: maxParticipants,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Community "${name}" created successfully!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => CommunityChatScreen(community: community)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create community: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}