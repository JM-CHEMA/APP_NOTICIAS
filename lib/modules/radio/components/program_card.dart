import 'package:flutter/material.dart';
import 'package:app_noticias/modules/radio/radio_theme.dart';
import 'package:app_noticias/modules/radio/models/program_model.dart';

class ProgramCard extends StatelessWidget {
  final ProgramModel program;
  final VoidCallback onTap;

  const ProgramCard({super.key, required this.program, required this.onTap});

  Widget _fallbackImage() {
    return const ColoredBox(
      color: Color(0xFF243B53),
      child: Center(
        child: Icon(Icons.headphones_rounded, size: 52, color: Colors.white70),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.medium),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          boxShadow: AppShadows.program,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          child:
                              program.imageUrl != null &&
                                  program.imageUrl!.isNotEmpty
                              ? Image.network(
                                  program.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _fallbackImage();
                                  },
                                )
                              : _fallbackImage(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.small),

                  Text(
                    program.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.stationTitle.copyWith(
                      fontSize: 14,
                      color: colors.onSurface,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.extraSmall),

                  Text(
                    program.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.stationDescription.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
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
