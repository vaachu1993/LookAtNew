import 'package:flutter/material.dart';

class RecentStoryCard extends StatelessWidget {
  final String image;
  final String publisher;
  final String title;
  final String timeAgo;
  final String readTime;

  const RecentStoryCard({
    super.key,
    required this.image,
    required this.publisher,
    required this.title,
    required this.timeAgo,
    required this.readTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Publisher logo
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              publisher[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFE20035),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Publisher name
              Text(
                publisher,
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),

              // Title
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),

              // Time info
              Row(
                children: [
                  Text(
                    timeAgo,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '•',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    readTime,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 80,
            height: 80,
            color: Colors.grey[300],
            child: Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image,
                    color: Colors.grey,
                    size: 30,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

