import 'package:PiliPlus/models_new/pgc/pgc_info_model/episode.dart';

class Section {
  List<EpisodeItem>? episodes;

  Section({
    this.episodes,
  });

  factory Section.fromJson(Map<String, dynamic> json) => Section(
    episodes: (json['episodes'] as List<dynamic>?)
        ?.map((e) => EpisodeItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
