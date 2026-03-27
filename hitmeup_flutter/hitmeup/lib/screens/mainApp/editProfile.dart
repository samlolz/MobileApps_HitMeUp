<<<<<<< HEAD:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/editProfile.dart
=======
import 'package:flutter/cupertino.dart';
>>>>>>> b08e7bd95fdc7cd8a471cf7b3f92860581c8f222:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/editProfile.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
	const EditProfileScreen({
		super.key,
		required this.initialName,
		required this.initialBirthday,
		required this.initialGender,
		required this.initialLocation,
		required this.initialInterests,
	});

	final String initialName;
	final String initialBirthday;
	final String initialGender;
	final String initialLocation;
	final List<String> initialInterests;

	@override
	State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
	late TextEditingController _nameController;
<<<<<<< HEAD:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/editProfile.dart
	late TextEditingController _birthdayController;
	late TextEditingController _genderController;
	late TextEditingController _locationController;
	late List<TextEditingController> _interestControllers;
=======
	late TextEditingController _genderController;
	late TextEditingController _locationController;
	late List<TextEditingController> _interestControllers;
	late DateTime _selectedBirthday;
>>>>>>> b08e7bd95fdc7cd8a471cf7b3f92860581c8f222:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/editProfile.dart

	@override
	void initState() {
		super.initState();
		_nameController = TextEditingController(text: widget.initialName);
<<<<<<< HEAD:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/editProfile.dart
		_birthdayController = TextEditingController(text: widget.initialBirthday);
		_genderController = TextEditingController(text: widget.initialGender);
		_locationController = TextEditingController(text: widget.initialLocation);
=======
		_genderController = TextEditingController(text: widget.initialGender);
		_locationController = TextEditingController(text: widget.initialLocation);
		_selectedBirthday = _parseBirthday(widget.initialBirthday);
>>>>>>> b08e7bd95fdc7cd8a471cf7b3f92860581c8f222:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/editProfile.dart
		_interestControllers = widget.initialInterests
			.map((interest) => TextEditingController(text: interest))
			.toList();
	}

	@override
	void dispose() {
		_nameController.dispose();
<<<<<<< HEAD:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/editProfile.dart
		_birthdayController.dispose();
=======
>>>>>>> b08e7bd95fdc7cd8a471cf7b3f92860581c8f222:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/editProfile.dart
		_genderController.dispose();
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
					automaticallyImplyLeading: true,
					backgroundColor: Colors.white,
					surfaceTintColor: Colors.white,
					elevation: 0,
					title: const Text(
						'Edit Profile',
						style: TextStyle(
							fontSize: 18,
							fontWeight: FontWeight.w600,
							color: Colors.black,
						),
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
													color: Color(0xFF2E8DFF),
												),
												child: const CircleAvatar(
													backgroundImage: AssetImage('assets/profilepic.png'),
												),
											),
											const SizedBox(height: 8),
											GestureDetector(
												onTap: () {
													// TODO: Implement image picker
												},
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
<<<<<<< HEAD:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/editProfile.dart
											_buildInputField(
												controller: _birthdayController,
												label: 'Birthday date',
											),
=======
											_buildBirthdayField(),
>>>>>>> b08e7bd95fdc7cd8a471cf7b3f92860581c8f222:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/editProfile.dart
											const SizedBox(height: 10),

											// Gender Field
											_buildInputField(
												controller: _genderController,
												label: 'Gender',
											),
											const SizedBox(height: 10),

											// Location Field
											_buildInputField(
												controller: _locationController,
												label: 'Location',
											),
											const SizedBox(height: 10),

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
														children: _interestControllers.asMap().entries.map((entry) {
															int index = entry.key;
															TextEditingController controller = entry.value;
															return Column(
																children: [
																	Container(
																							padding: const EdgeInsets.symmetric(horizontal: 8),
																		decoration: BoxDecoration(
																			color: Colors.white,
																			borderRadius: BorderRadius.circular(8),
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
																									contentPadding: EdgeInsets.symmetric(vertical: 5),
																			),
																			style: const TextStyle(
																				fontSize: 11,
																				color: Colors.black,
																			),
																		),
																	),
																	if (index < _interestControllers.length - 1)
																		const SizedBox(height: 8),
																],
															);
														}).toList(),
													),
												),
											],
										),
										const SizedBox(height: 24),

											// Done Button
											SizedBox(
												width: 200,
												height: 40,
												child: ElevatedButton(
													onPressed: _savProfile,
													style: ElevatedButton.styleFrom(
														backgroundColor: const Color(0xFFF83D8D),
														foregroundColor: Colors.white,
														shape: RoundedRectangleBorder(
															borderRadius: BorderRadius.circular(20),
														),
														elevation: 0,
													),
													child: const Text(
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
				)
			),
		);
	}

	Widget _buildInputField({
		required TextEditingController controller,
		required String label,
	}) {
		return Row(
			children: [
				SizedBox(
					width: 100,
					child: Text(
						label,
						style: const TextStyle(
							fontSize: 11,
							fontWeight: FontWeight.w600,
							color: Color(0xFF202020),
						),
					),
				),
				Expanded(
					child: Container(
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
							controller: controller,
							decoration: const InputDecoration(
												isDense: true,
								border: InputBorder.none,
												contentPadding: EdgeInsets.symmetric(vertical: 5),
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

<<<<<<< HEAD:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/editProfile.dart
=======
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

>>>>>>> b08e7bd95fdc7cd8a471cf7b3f92860581c8f222:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/editProfile.dart
	void _savProfile() {
		// Collect all the edited data
		final updatedData = {
			'name': _nameController.text,
<<<<<<< HEAD:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/editProfile.dart
			'birthday': _birthdayController.text,
=======
			'birthday': _formatBirthday(_selectedBirthday),
>>>>>>> b08e7bd95fdc7cd8a471cf7b3f92860581c8f222:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/editProfile.dart
			'gender': _genderController.text,
			'location': _locationController.text,
			'interests': _interestControllers.map((c) => c.text).toList(),
		};

		// Return the updated data
		Navigator.of(context).pop(updatedData);
	}
}
