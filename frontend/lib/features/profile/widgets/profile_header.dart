import 'package:flutter/material.dart';
import '../model/user_profile.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback? onEditPhoto;
  final bool isLoading;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.onEditPhoto,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xff0EA5A4).withOpacity(0.9),
            const Color(0xff0891B2).withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              // Profile Avatar Container
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isLoading
                      ? Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(16),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.white,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xff0EA5A4),
                                  const Color(0xff0891B2),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                profile?.initials ?? 'U',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              // Edit button overlay
              if (onEditPhoto != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onEditPhoto,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Color(0xff0EA5A4),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            profile?.displayName ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (profile?.email != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                profile!.email!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}