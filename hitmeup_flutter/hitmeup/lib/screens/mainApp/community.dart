import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class CommunityScreen extends StatelessWidget {
	const CommunityScreen({super.key});

	static const List<_CommunityRowData> _communityRows = [
		_CommunityRowData(
			title: 'Teman Jakarta',
			description: 'CARI TEMAN DEARAH JAKARTA',
			participants: '123.000 users',
			imageUrl: 'https://i.pravatar.cc/180?img=15',
		),
		_CommunityRowData(
			title: 'VESPA RIDING COMMUNITY JKT',
			description: 'RIDING BARENG SARI KALI',
			participants: '51.027 users',
			imageUrl: 'https://i.pravatar.cc/180?img=31',
		),
		_CommunityRowData(
			title: 'JAKARTA PADEL SOCIETY',
			description: 'GASSS PADEELLL JKTTT',
			participants: '2.003 users',
			imageUrl: 'https://i.pravatar.cc/180?img=46',
		),
	];

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Colors.transparent,
			appBar: AppBar(
				automaticallyImplyLeading: false,
				backgroundColor: const Color.fromARGB(255, 255, 255, 255),
				elevation: 0,
				leading: IconButton(
					onPressed: () => Navigator.of(context).maybePop(),
					icon: const Icon(Icons.arrow_back_ios_new_rounded),
					color: AppColors.textDark,
				),
				title: Text(
					'Community',
					style: AppTextStyles.heading.copyWith(color: Colors.black),
				),
			),
			body: DecoratedBox(
				decoration: const BoxDecoration(gradient: AppGradient.background),
				child: SafeArea(
					top: false,
					child: Column(
						children: [
							Expanded(
								child: Padding(
									padding: const EdgeInsets.fromLTRB(6, 12, 6, 0),
									child: Column(
										children: [
											Container(
												height: 40,
												padding: const EdgeInsets.symmetric(horizontal: 10),
												decoration: BoxDecoration(
													color: Colors.white,
													borderRadius: BorderRadius.circular(12),
												),
												child: const Row(
													children: [
														Icon(
															Icons.search_rounded,
															color: Colors.black,
															size: 22,
														),
														SizedBox(width: 6),
														Expanded(
															child: TextField(
																decoration: InputDecoration(
																	isCollapsed: true,
																	hintText: 'Search communities',
																	hintStyle: TextStyle(
																		color: Color(0xFF8C8C8C),
																		fontSize: 16,
																		fontWeight: FontWeight.w600,
																	),
																	border: InputBorder.none,
																),
																style: TextStyle(
																	color: AppColors.textDark,
																	fontSize: 16,
																	fontWeight: FontWeight.w600,
																),
															),
														),
													],
												),
											),
											const SizedBox(height: 10),
											Expanded(
												child: ListView.separated(
													itemCount: _communityRows.length,
													separatorBuilder: (_, __) => const SizedBox(height: 10),
													itemBuilder: (context, index) {
														final row = _communityRows[index];
														return _CommunityListTile(
															data: row,
															onTap: () => _showJoinCommunityDialog(context, row),
														);
													},
												),
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

	void _showJoinCommunityDialog(BuildContext context, _CommunityRowData row) {
		showDialog<void>(
			context: context,
			barrierDismissible: true,
			barrierColor: Colors.transparent,
			builder: (dialogContext) {
				return Dialog(
					backgroundColor: Colors.transparent,
					insetPadding: const EdgeInsets.symmetric(horizontal: 14),
					child: Container(
						padding: const EdgeInsets.all(16),
						decoration: BoxDecoration(
							gradient: AppGradient.background,
							borderRadius: BorderRadius.circular(15),
						),
						child: Container(
							padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
							decoration: BoxDecoration(
								color: Colors.white.withValues(alpha: 0.95),
								borderRadius: BorderRadius.circular(14),
							),
							child: Column(
								mainAxisSize: MainAxisSize.min,
								children: [
									const Text(
										'Do you want to join this community?',
										textAlign: TextAlign.center,
										style: TextStyle(
											color: AppColors.textDark,
											fontSize: 20,
											fontWeight: FontWeight.w800,
										),
									),
									const SizedBox(height: 10),
									ClipOval(
										child: Image.network(
											row.imageUrl,
											width: 130,
											height: 130,
											fit: BoxFit.cover,
										),
									),
									const SizedBox(height: 10),
									Text(
										row.title,
										textAlign: TextAlign.center,
										style: const TextStyle(
											color: AppColors.textDark,
											fontSize: 20,
											fontWeight: FontWeight.w800,
										),
									),
									const SizedBox(height: 4),
									Text(
										row.participants,
										style: const TextStyle(
											color: Color(0xFF585858),
											fontSize: 13,
											fontWeight: FontWeight.w600,
										),
									),
									const SizedBox(height: 14),
									Row(
										mainAxisAlignment: MainAxisAlignment.spaceAround,
										children: [
											_DecisionButton(
												backgroundColor: const Color(0xFFFF2020),
												icon: Icons.close_rounded,
												onTap: () => Navigator.of(dialogContext).pop(),
											),
											_DecisionButton(
												backgroundColor: const Color(0xFF2CC2AA),
												icon: Icons.check_rounded,
												onTap: () => Navigator.of(dialogContext).pop(),
											),
										],
									),
								],
							),
						),
					),
				);
			},
		);
	}
}

class _CommunityListTile extends StatelessWidget {
	const _CommunityListTile({required this.data, required this.onTap});

	final _CommunityRowData data;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		return Material(
			color: Colors.transparent,
			child: InkWell(
				onTap: onTap,
				borderRadius: BorderRadius.circular(12),
				child: Container(
					width: double.infinity,
					padding: const EdgeInsets.all(8),
					decoration: BoxDecoration(
						color: Colors.white.withValues(alpha: 0.92),
						borderRadius: BorderRadius.circular(12),
					),
					child: Row(
						children: [
							ClipRRect(
								borderRadius: BorderRadius.circular(6),
								child: Image.network(
									data.imageUrl,
									width: 50,
									height: 50,
									fit: BoxFit.cover,
								),
							),
							const SizedBox(width: 10),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											data.title,
											maxLines: 1,
											overflow: TextOverflow.ellipsis,
											style: const TextStyle(
												color: AppColors.textDark,
												fontSize: 14,
												fontWeight: FontWeight.w800,
											),
										),
										const SizedBox(height: 2),
										Text(
											data.subtitle,
											maxLines: 1,
											overflow: TextOverflow.ellipsis,
											style: const TextStyle(
												color: Color(0xFF4A4A4A),
												fontSize: 10,
												fontWeight: FontWeight.w600,
											),
										),
									],
								),
							),
						],
					),
				),
			),
		);
	}
}

class _CommunityRowData {
	const _CommunityRowData({
		required this.title,
		required this.description,
		required this.participants,
		required this.imageUrl,
	});

	final String title;
	final String description;
	final String participants;
	final String imageUrl;

	String get subtitle => '$description  •  $participants';
}

class _DecisionButton extends StatelessWidget {
	const _DecisionButton({
		required this.backgroundColor,
		required this.icon,
		required this.onTap,
	});

	final Color backgroundColor;
	final IconData icon;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		return Material(
			color: Colors.transparent,
			child: InkWell(
				onTap: onTap,
				borderRadius: BorderRadius.circular(999),
				child: Container(
					width: 58,
					height: 58,
					decoration: BoxDecoration(
						color: backgroundColor,
						shape: BoxShape.circle,
					),
					child: Icon(icon, color: Colors.white, size: 40),
				),
			),
		);
	}
}
