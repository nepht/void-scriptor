/// Creator visibility: whether a creator profile is visible to others.
enum CreatorVisibility { private, unlisted, public }

/// A creator identity attached to a user account.
///
/// Sprint 43 — Creator Profile Model.
/// A user account may stay private (no public creator identity) or activate
/// a public profile with portfolio, skills, and AI studio.
class CreatorProfile {
  const CreatorProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    this.bio,
    this.avatarAssetId,
    this.bannerAssetId,
    this.skills = const [],
    this.specialties = const [],
    this.portfolioProjectIds = const [],
    this.visibility = CreatorVisibility.private,
  });

  final String id;
  final String userId;

  final String displayName;
  final String? bio;
  final String? avatarAssetId;
  final String? bannerAssetId;

  final List<String> skills;
  final List<String> specialties;
  final List<String> portfolioProjectIds;

  final CreatorVisibility visibility;

  CreatorProfile copyWith({
    String? displayName,
    String? bio,
    String? avatarAssetId,
    String? bannerAssetId,
    List<String>? skills,
    List<String>? specialties,
    List<String>? portfolioProjectIds,
    CreatorVisibility? visibility,
  }) {
    return CreatorProfile(
      id: id,
      userId: userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarAssetId: avatarAssetId ?? this.avatarAssetId,
      bannerAssetId: bannerAssetId ?? this.bannerAssetId,
      skills: skills ?? this.skills,
      specialties: specialties ?? this.specialties,
      portfolioProjectIds: portfolioProjectIds ?? this.portfolioProjectIds,
      visibility: visibility ?? this.visibility,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'displayName': displayName,
    'bio': bio,
    'avatarAssetId': avatarAssetId,
    'bannerAssetId': bannerAssetId,
    'skills': skills,
    'specialties': specialties,
    'portfolioProjectIds': portfolioProjectIds,
    'visibility': visibility.name,
  };

  factory CreatorProfile.fromJson(Map<String, dynamic> json) {
    return CreatorProfile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      bio: json['bio'] as String?,
      avatarAssetId: json['avatarAssetId'] as String?,
      bannerAssetId: json['bannerAssetId'] as String?,
      skills: (json['skills'] as List<dynamic>? ?? []).cast<String>(),
      specialties: (json['specialties'] as List<dynamic>? ?? []).cast<String>(),
      portfolioProjectIds: (json['portfolioProjectIds'] as List<dynamic>? ?? [])
          .cast<String>(),
      visibility: CreatorVisibility.values.firstWhere(
        (v) => v.name == json['visibility'],
        orElse: () => CreatorVisibility.private,
      ),
    );
  }
}
