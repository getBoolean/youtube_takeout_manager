import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_button.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import '../skeleton.dart';

class ChannelLoadingSkeleton extends StatelessWidget {
  const ChannelLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: !context.router.canPop()
            ? BackButton(
                onPressed: () =>
                    context.router.replaceAll([const ChannelListRoute()]),
              )
            : null,
        actions: const [AccountButton()],
        title: const Row(
          children: [
            SkeletonAvatar(),
            SizedBox(width: 12),
            SkeletonLine(width: 120, height: 16),
          ],
        ),
      ),
      body: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonAvatar(),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: double.infinity, height: 12),
                    SizedBox(height: 8),
                    SkeletonLine(width: 200, height: 12),
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
