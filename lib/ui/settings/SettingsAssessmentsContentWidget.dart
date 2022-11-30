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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/flex_ui.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/ui/widgets/InfoPopup.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';

class SettingsAssessmentsContentWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsAssessmentsContentWidgetState();
}

class _SettingsAssessmentsContentWidgetState extends State<SettingsAssessmentsContentWidget> implements NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [AppLivecycle.notifyStateChanged]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if ((name == AppLivecycle.notifyStateChanged) && (param == AppLifecycleState.resumed)) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['assessments'] ?? [];
    for (String code in codes) {
      if (code == 'settings') {
        contentList.addAll(_buildAssessmentsSettings());
      }
    }

    if (contentList.isNotEmpty) {
      contentList.insert(0, Container(height: 8));
      contentList.add(Container(height: 16));
    }

    return Container(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList));
  }

  List<Widget> _buildAssessmentsSettings() {
    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['assessments.settings'] ?? [];
    for (String code in codes) {
      if (code == 'skills_self_evaluation') {
        contentList.add(Padding(padding: const EdgeInsets.only(top: 16, bottom: 4), child: Row(children: [
          Expanded(
              child: Text('Skills Self-Evaluation',
                  style:  Styles().textStyles?.getTextStyle("widget.detail.regular.fat")))
        ])));

        List<dynamic> bessiCodes = FlexUI()['assessments.settings.skills_self_evaluation'] ?? [];
        for (String bessiCode in bessiCodes) {
          if (bessiCode == 'save') {
            contentList.add(ToggleRibbonButton(
                label: Localization().getStringEx('panel.settings.home.assessments.skills_self_evaluation.save_results.label', 'Save my results to compare to future results'),
                toggled: Storage().assessmentsSaveResultsMap?['bessi'] ?? Auth2().privacyMatch(4),
                border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
                borderRadius: BorderRadius.all(Radius.circular(4)),
                onTap: _onSaveBessi));
          } else if (bessiCode == 'save_progress') {
            contentList.add(Text(
              Localization().getStringEx('panel.settings.home.assessments.skills_self_evaluation.save_progress.description', 'Progress on an evaluation that you started will be saved automatically until you cancel or complete it.'),
              style:  Styles().textStyles?.getTextStyle("widget.item.small.thin")
            ));
          }
        }
        
      }
    }

    return contentList;
  }

  void _onSaveBessi() {
    Analytics().logSelect(target: 'Save skills self-evaluation results');
    if (Auth2().privacyMatch(4)) {
      setState(() {
        Map<String, bool> assessmentsSaveResultsMap = Storage().assessmentsSaveResultsMap ?? {};
        assessmentsSaveResultsMap['bessi'] = !(assessmentsSaveResultsMap['bessi'] ?? false);
        Storage().assessmentsSaveResultsMap = assessmentsSaveResultsMap;
      });
    } else {
      Widget infoTextWidget = RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: Localization().getStringEx('panel.skills_self_evaluation.get_started.auth_dialog.prefix', 'You need to be signed in with your NetID to access Assessments.\n'),
              style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.fillColorPrimaryVariant),
            ),
            WidgetSpan(
              child: InkWell(onTap: _onTapPrivacyLevel, child: Text(
                Localization().getStringEx('panel.skills_self_evaluation.get_started.auth_dialog.privacy', 'Set your privacy level to 4 or 5.'),
                style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.fillColorPrimaryVariant, decoration: TextDecoration.underline, decorationColor: Styles().colors?.fillColorSecondary),
              )),
            ),
            TextSpan(
              text: Localization().getStringEx('panel.skills_self_evaluation.get_started.auth_dialog.suffix', ' Then, sign in with your NetID under Settings.'),
              style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.fillColorPrimaryVariant),
            ),
          ],
        ),
      );
      showDialog(context: context, builder: (_) => InfoPopup(
        backColor: Styles().colors?.surface,
        padding: EdgeInsets.only(left: 24, right: 24, top: 28, bottom: 24),
        alignment: Alignment.center,
        infoTextWidget: infoTextWidget,
        closeIcon: Image.asset('images/close-orange-small.png'),
      ),);
    }
  }

  void _onTapPrivacyLevel() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,)));
  }
}
