import 'package:flutter/material.dart';

class FeaturedNewsCard extends StatelessWidget {
  final String image;
  final String publisher;
  final String title;
  final String timeAgo;
  final String readTime;

  const FeaturedNewsCard({
    super.key,
    required this.image,
    required this.publisher,
    required this.title,
    required this.timeAgo,
    required this.readTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              height: 160,
              color: Colors.grey[800],
              child: Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 50,
                    ),
                  );
                },
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Publisher
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE20035),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fiber_manual_record,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      publisher,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
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
        ],
      ),
    );
  }
}

