import 'package:flutter/material.dart';

class CustomItemCard extends StatelessWidget {
  final String title;
  final String ?subtitle;
  final String? rightLabel;
  final String rightValue;
  final Color rightValueColor;
  final IconData? icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final VoidCallback? onTap;
  final Widget? customTrailing;

  const CustomItemCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.rightValue,
    this.rightLabel,
    this.rightValueColor = const Color(0xFFE53935), // Default merah
    this.icon = Icons.person,
    this.iconColor = const Color(0xFFFF9800),
    this.iconBackgroundColor = const Color(0xFFFFF3E0),
    this.onTap,
    this.customTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon Avatar Bulat
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // Info Kiri (Judul & Subtitle)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                   
                  ],
                ),
              ),

              // Info Kanan / Custom Trailing Widget
              if (customTrailing != null)
                customTrailing!
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (rightLabel != null) ...[
                      Text(
                        rightLabel!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      rightValue,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: rightValueColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}