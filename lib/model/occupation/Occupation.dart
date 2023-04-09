import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'Skill.dart';

class Occupation {
  String? code;
  String? title;
  String? description;
  String? onetLink;
  List<Skill>? skills;
  List<Skill>? technicalSkills;

  Occupation({
    this.code,
    this.title,
    this.description,
    this.onetLink,
    this.skills,
    this.technicalSkills,
  });

  factory Occupation.fromJson(Map<String, dynamic> json) {
    return Occupation(
      code: JsonUtils.stringValue(json["code"]) ?? "",
      title: JsonUtils.stringValue(json["title"]) ?? "",
      description: JsonUtils.stringValue(json["description"]) ?? "",
      onetLink: JsonUtils.stringValue(json["onetLink"]) ?? "",
      skills: Skill.listFromJson(json["skills"]) ?? [],
      technicalSkills: Skill.listFromJson(json["technicalSkills"]) ?? [],
    );
  }

  static List<Occupation>? listFromJson(List<dynamic>? jsonList) {
    List<Occupation>? result;
    if (jsonList != null) {
      result = <Occupation>[];
      for (dynamic jsonEntry in jsonList) {
        Map<String, dynamic>? mapVal = JsonUtils.mapValue(jsonEntry);
        if (mapVal != null) {
          try {
            ListUtils.add(result, Occupation.fromJson(mapVal));
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      }
    }
    return result;
  }

  @override
  String toString() {
    return 'Occupation(code: $code, title: $title, description: $description, onetLink: $onetLink, skills: $skills, technicalSkills: $technicalSkills)';
  }
}
