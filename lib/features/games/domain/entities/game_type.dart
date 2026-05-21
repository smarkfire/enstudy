import 'package:flutter/material.dart';

enum GameType {
  match(displayName: '配对消消乐', icon: Icons.grid_view),
  spell(displayName: '拼写挑战', icon: Icons.edit),
  listen(displayName: '听力选择', icon: Icons.headphones),
  fillBlank(displayName: '填空达人', icon: Icons.text_fields),
  speed(displayName: '速度对决', icon: Icons.speed),
  reorder(displayName: '短语重组', icon: Icons.reorder),
  shooting(displayName: '单词射击', icon: Icons.gps_fixed),
  whack(displayName: '疯狂打地鼠', icon: Icons.sports_esports);

  const GameType({required this.displayName, required this.icon});

  final String displayName;
  final IconData icon;
}
