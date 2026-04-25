import 'package:flutter/material.dart';
import '../model/user_profile.dart';

// ─── Design tokens (matches app-wide Google blue theme) ──────────────────────
const _blue      = Color(0xFF1A73E8);
const _blueLight = Color(0xFFE8F0FE);
const _bgPage    = Color(0xFFF6F8FC);
const _textPri   = Color(0xFF1F1F1F);
const _textSec   = Color(0xFF5F6368);

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
    final initials = profile?.initials ?? 'U';
    final name     = profile?.displayName ?? 'User';
    final email    = profile?.email;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
      child: Column(
        children: [
          // ── Single clean circle avatar ─────────────────────────────────
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _blueLight,
                  border: Border.all(
                    color: _blue.withOpacity(0.18),
                    width: 2,
                  ),
                ),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_blue),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: _blue,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
              ),
              // Edit badge (only in edit mode)
              if (onEditPhoto != null)
                GestureDetector(
                  onTap: onEditPhoto,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Name ──────────────────────────────────────────────────────
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _textPri,
              letterSpacing: -0.3,
            ),
          ),

          // ── Email chip ────────────────────────────────────────────────
          if (email != null) ...[
            const SizedBox(height: 6),
            Text(
              email,
              style: const TextStyle(
                fontSize: 13,
                color: _textSec,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}