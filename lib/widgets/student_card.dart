import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/student_model.dart';
import '../constants/admin_colors.dart';

class StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;
  final VoidCallback onClipboardTap;

  const StudentCard({
    super.key,
    required this.student,
    required this.onTap,
    required this.onClipboardTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: student.isExpired
              ? AdminColors.cardExpiredBackground
              : AdminColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: student.isExpired
              ? Border.all(color: AdminColors.expiredRed.withValues(alpha: 0.4))
              : Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone do perfil
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.people_alt_outlined,
                color: AdminColors.textPurple,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Informações do Aluno
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      color: AdminColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Username Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AdminColors.tagPurple,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '@${student.nickname}',
                          style: const TextStyle(
                            color: AdminColors.textPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (student.isExpired) ...[
                        const SizedBox(width: 6),
                        // Badge de Expirado
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AdminColors.expiredRed.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'EXPIRADO',
                            style: TextStyle(
                              color: AdminColors.expiredRed,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${student.weight.toInt()}kg • ${student.objective}',
                    style: const TextStyle(
                      color: AdminColors.textSub,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12,
                        color: AdminColors.textSub,
                      ),
                      children: [
                        TextSpan(
                          text:
                              'início: ${dateFormat.format(student.startDate)}',
                        ),
                        if (student.endDate != null) ...[
                          TextSpan(
                            text:
                                ' → venc: ${dateFormat.format(student.endDate!)}',
                            style: TextStyle(
                              color: student.isExpired
                                  ? AdminColors.expiredRed
                                  : AdminColors.textSub,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Ações do Card
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onClipboardTap,
                  icon: const Icon(Icons.assignment_outlined, size: 20),
                  color: AdminColors.textSub,
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AdminColors.textSub,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
