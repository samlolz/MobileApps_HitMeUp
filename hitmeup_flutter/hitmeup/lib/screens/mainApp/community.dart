import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../services/chat_service.dart';
import '../../services/auth_session.dart';
import 'chat.dart';
import 'chat_models.dart';
import 'community_chat_screen.dart';

class CommunityScreen extends StatefulWidget {
	const CommunityScreen({super.key});

	@override
	State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
	late TextEditingController _searchController;
	List<_CommunityRowData> _allCommunities = [];
	List<_CommunityRowData> _filteredCommunities = [];
	bool _isLoading = true;
	String? _errorMessage;

	@override
	void initState() {
		super.initState();
		_searchController = TextEditingController();
		_searchController.addListener(_filterCommunities);
		_fetchCommunities();
	}

	@override
	void dispose() {
		_searchController.dispose();
		super.dispose();
	}

	Future<void> _fetchCommunities() async {
		try {
			setState(() {
				_isLoading = true;
				_errorMessage = null;
			});

			final communities = await ChatService.fetchCommunities();
			
			final communityRows = communities.map((community) {
				final hasImage = community['communityPicture'] != null;
				return _CommunityRowData(
					id: community['id'],
					title: community['name'] ?? 'Unknown Community',
					description: community['description'] ?? 'No description',
					participants: '${community['totalParticipants'] ?? 0} users',
					imageUrl: hasImage ? _resolveCommunityImageUrl(community['communityPicture']) : 'assets/FallBackProfile.png',
					isAsset: !hasImage,
				);
			}).toList();

			setState(() {
				_allCommunities = communityRows;
				_filteredCommunities = communityRows;
				_isLoading = false;
			});
		} catch (e) {
			setState(() {
				_errorMessage = 'Failed to load communities: $e';
				_isLoading = false;
			});
		}
	}

	String _extractBaseUrl() {
		const overrideUrl = String.fromEnvironment('SIGNUP_API_BASE_URL');
		if (overrideUrl.isNotEmpty) {
			return overrideUrl;
		}
		return 'http://10.0.2.2:8000';
	}

	String _resolveCommunityImageUrl(dynamic rawPath) {
		final value = (rawPath ?? '').toString().trim();
		if (value.isEmpty) {
			return 'assets/FallBackProfile.png';
		}

		if (value.startsWith('http://') || value.startsWith('https://')) {
			return value;
		}

		final base = _extractBaseUrl().replaceAll(RegExp(r'/+$'), '');
		final path = value.startsWith('/') ? value : '/$value';
		return '$base$path';
	}

	void _filterCommunities() {
		final query = _searchController.text.toLowerCase();
		setState(() {
			if (query.isEmpty) {
				_filteredCommunities = _allCommunities;
			} else {
				_filteredCommunities = _allCommunities.where((community) {
					return community.title.toLowerCase().contains(query) ||
						community.description.toLowerCase().contains(query);
				}).toList();
			}
		});
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Colors.transparent,
			appBar: AppBar(
				automaticallyImplyLeading: false,
				backgroundColor: const Color.fromARGB(255, 255, 255, 255),
				elevation: 0,
        titleSpacing: 8,
				leading: IconButton(
					onPressed: () => Navigator.of(context).pushReplacement(
						MaterialPageRoute(builder: (_) => const ChatScreen()),
					),
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
												child: Row(
													children: [
														const Icon(
															Icons.search_rounded,
															color: Colors.black,
															size: 22,
														),
														const SizedBox(width: 6),
														Expanded(
															child: TextField(
																controller: _searchController,
																decoration: const InputDecoration(
																	isCollapsed: true,
																	hintText: 'Search communities',
																	hintStyle: TextStyle(
																		color: Color(0xFF8C8C8C),
																		fontSize: 16,
																		fontWeight: FontWeight.w600,
																	),
																	border: InputBorder.none,
																),
																style: const TextStyle(
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
												child: _buildCommunityList(),
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

	Widget _buildCommunityList() {
		if (_isLoading) {
			return const Center(
				child: CircularProgressIndicator(
					valueColor: AlwaysStoppedAnimation<Color>(AppColors.pinkTop),
				),
			);
		}

		if (_errorMessage != null) {
			return Center(
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						const Icon(Icons.error_outline, color: AppColors.pinkTop, size: 48),
						const SizedBox(height: 16),
						Text(
							_errorMessage!,
							textAlign: TextAlign.center,
							style: const TextStyle(color: AppColors.textDark, fontSize: 14),
						),
						const SizedBox(height: 16),
						ElevatedButton(
							onPressed: _fetchCommunities,
							style: ElevatedButton.styleFrom(
								backgroundColor: AppColors.pinkTop,
							),
							child: const Text('Retry', style: TextStyle(color: Colors.white)),
						),
					],
				),
			);
		}

		if (_filteredCommunities.isEmpty) {
			return Center(
				child: Text(
					_searchController.text.isEmpty
						? 'No communities available'
						: 'No communities found',
					style: const TextStyle(
						color: AppColors.textDark,
						fontSize: 16,
						fontWeight: FontWeight.w600,
					),
				),
			);
		}

		return ListView.separated(
			itemCount: _filteredCommunities.length,
			separatorBuilder: (_, __) => const SizedBox(height: 10),
			itemBuilder: (context, index) {
				final row = _filteredCommunities[index];
				return _CommunityListTile(
					data: row,
					onTap: () => _showJoinCommunityDialog(context, row),
				);
			},
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
										child: row.isAsset
											? Image.asset(
												row.imageUrl,
												width: 130,
												height: 130,
												fit: BoxFit.cover,
											)
											: Image.network(
												row.imageUrl,
												width: 130,
												height: 130,
												fit: BoxFit.cover,
												errorBuilder: (_, __, ___) => Image.asset(
													'assets/FallBackProfile.png',
													width: 130,
													height: 130,
													fit: BoxFit.cover,
												),
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
												onTap: () {
													_handleJoinCommunity(row, dialogContext);
												},
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

	Future<void> _handleJoinCommunity(_CommunityRowData row, BuildContext dialogContext) async {
		final userId = AuthSession.instance.userId;
		if (userId == null) {
			if (mounted) {
				Navigator.of(dialogContext).pop();
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Please log in to join communities.')),
				);
			}
			return;
		}

		try {
			await ChatService.addUserToCommunity(userId: userId, communityId: row.id);
			if (!mounted) return;

			Navigator.of(dialogContext).pop();
		Navigator.of(context).push(
			MaterialPageRoute(
				builder: (_) => CommunityChatScreen(
					community: Community(
						id: row.id.toString(),
						name: row.title,
						participants: int.tryParse(
							row.participants.replaceAll(RegExp(r'[^0-9]'), ''),
						) ?? 0,
						imageUrl: row.imageUrl,
					),
				),
			),
		);
		} catch (e) {
			if (!mounted) return;

			Navigator.of(dialogContext).pop();
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
					content: Text('Failed to join community. Please try again.'),
					backgroundColor: Colors.red,
				),
			);
		}
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
								child: data.isAsset
									? Image.asset(
										data.imageUrl,
										width: 50,
										height: 50,
										fit: BoxFit.cover,
									)
									: Image.network(
										data.imageUrl,
										width: 50,
										height: 50,
										fit: BoxFit.cover,
										errorBuilder: (_, __, ___) => Image.asset(
											'assets/FallBackProfile.png',
											width: 50,
											height: 50,
											fit: BoxFit.cover,
										),
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
		required this.id,
		required this.title,
		required this.description,
		required this.participants,
		required this.imageUrl,
		this.isAsset = false,
	});

	final int id;
	final String title;
	final String description;
	final String participants;
	final String imageUrl;
	final bool isAsset;

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
