import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/routing/app_router.dart';

class ChannelLoadingSkeleton extends StatelessWidget {
  const ChannelLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skeletonColor = theme.colorScheme.surfaceContainerHighest;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: !context.router.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.router.replaceAll([
                  const HomeRoute(),
                  const ChannelListRoute(),
                ]),
              )
            : null,
        title: Row(
          children: [
            CircleAvatar(radius: 16, backgroundColor: skeletonColor),
            const SizedBox(width: 12),
            Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 16, backgroundColor: skeletonColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 200,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
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
