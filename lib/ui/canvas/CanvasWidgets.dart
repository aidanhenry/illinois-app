/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CanvasCourseCard extends StatefulWidget {
  final CanvasCourse course;
  final bool isSmall;

  CanvasCourseCard({required this.course, this.isSmall = false});

  @override
  State<CanvasCourseCard> createState() => _CanvasCourseCardState();
}

class _CanvasCourseCardState extends State<CanvasCourseCard> {
  double? _currentScore;
  bool _scoreLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCourseScore();
  }

  void _loadCourseScore() {
    _setScoreLoading(true);
    Canvas().loadCourseGradeScore(widget.course.id!).then((score) {
      _currentScore = score;
      _setScoreLoading(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color defaultColor = Colors.black;
    final double cardHeight = (MediaQuery.of(context).textScaleFactor * 130);
    double cardInnerPadding = 10;
    final double? cardWidth = widget.isSmall ? (MediaQuery.of(context).textScaleFactor * 200) : null;
    const double borderRadiusValue = 6;
    Color? mainColor = StringUtils.isNotEmpty(widget.course.courseColor) ? UiColors.fromHex(widget.course.courseColor!) : defaultColor;
    if (mainColor == null) {
      mainColor = defaultColor;
    }
    return Container(
        height: (widget.isSmall ? cardHeight : null),
        width: cardWidth,
        decoration: BoxDecoration(
            borderRadius: (widget.isSmall ? BorderRadius.circular(borderRadiusValue) : null),
            boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              height: (cardHeight / 2),
              decoration: BoxDecoration(
                  color: mainColor, borderRadius: (widget.isSmall ? BorderRadius.vertical(top: Radius.circular(borderRadiusValue)) : null)),
              child: Padding(
                  padding: EdgeInsets.only(left: cardInnerPadding, top: cardInnerPadding),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Styles().colors!.white),
                        child: _buildGradeScoreWidget(courseColor: mainColor))
                  ]))),
          Container(
              decoration: BoxDecoration(
                  color: Styles().colors!.white,
                  borderRadius: (widget.isSmall ? BorderRadius.vertical(bottom: Radius.circular(borderRadiusValue)) : null)),
              child: Padding(
                  padding: EdgeInsets.all(cardInnerPadding),
                  child: Row(children: [
                    Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(StringUtils.ensureNotEmpty(widget.course.name),
                          maxLines: (widget.isSmall ? 2 : 5),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: mainColor, fontSize: 18, fontFamily: Styles().fontFamilies!.extraBold))
                    ]))
                  ])))
        ]));
  }

  Widget _buildGradeScoreWidget({required Color courseColor}) {
    if (_scoreLoading) {
      double indicatorSize = 20;
      return SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: Padding(padding: EdgeInsets.all(5), child: CircularProgressIndicator(strokeWidth: 1, color: courseColor)));
    } else {
      return Text(_formattedGradeScore, style: TextStyle(color: courseColor, fontSize: 16, fontFamily: Styles().fontFamilies!.bold));
    }
  }

  String get _formattedGradeScore {
    if (_currentScore == null) {
      return 'N/A';
    }
    NumberFormat numFormatter = NumberFormat();
    numFormatter.minimumFractionDigits = 0;
    numFormatter.maximumFractionDigits = 2;
    return numFormatter.format(_currentScore) + '%';
  }

  void _setScoreLoading(bool loading) {
    _scoreLoading = loading;
    if (mounted) {
      setState(() {});
    }
  }
}
