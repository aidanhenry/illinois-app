/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Event2SetupSurveyPanel extends StatefulWidget {
  final Event2? event;
  final Event2SurveyDetails? surveyDetails;

  Event2SetupSurveyPanel({Key? key, this.event, this.surveyDetails}) : super(key: key);

  Event2SurveyDetails? get details => (event?.id != null) ? event?.surveyDetails : surveyDetails;

  @override
  State<StatefulWidget> createState() => _Event2SetupSurveyPanelState();
}

class _Event2SetupSurveyPanelState extends State<Event2SetupSurveyPanel>  {

  List<Survey>? _surveys;

  Survey? _survey;
  String? _initialSurveyId;
  
  final TextEditingController _hoursController = TextEditingController();
  late String _initialHours;

  bool _modified = false;
  bool _loadingSurveys = false;
  bool _updatingSurvey = false;

  @override
  void initState() {
    _initialSurveyId = widget.details?.surveyId;
    _hoursController.text = _initialHours = widget.details?.hoursAfterEvent?.toString() ?? '';
    if (_isEditing) {
      _hoursController.addListener(_checkModified);
    }

    _loadingSurveys = true;
    Surveys().loadSurveys().then((surveys) {
      setStateIfMounted(() {
        _surveys = surveys;
        _survey = ((_surveys != null) && (_initialSurveyId != null)) ? Survey.findInList(_surveys, id: _initialSurveyId) : null;
        _loadingSurveys = false;
      });
      _checkModified();
    });

    super.initState();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _headerBar,
        body: _buildScaffoldContent(),
        backgroundColor: Styles().colors!.white);
  }

  Widget _buildScaffoldContent() {
    if (_loadingSurveys) {
      return _buildLoadingContent();
    }
    else if (_surveys == null) {
      return _buildMessageContent(Localization().getStringEx('panel.event2.setup.survey.surveys.failed.msg', 'Failed to load available surveys.'));
    }
    else if ((_surveys?.length ?? 0) == 0) {
      return _buildMessageContent(Localization().getStringEx('panel.event2.setup.survey.surveys.empty.msg', 'There are no surveys available.'));
    }
    else {
      return _buildPanelContent();
    }
  }

  Widget _buildPanelContent() {
    return SingleChildScrollView(child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSurveysSection(),
          _buildHoursSection(),
        ])
      )
    );
  }

  Widget _buildLoadingContent() {
    return Column(children: [
      Expanded(flex: 1, child: Container(),),
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 3,),
      ),
      Expanded(flex: 2, child: Container(),),
    ],);
  }

  Widget _buildMessageContent(String? message) {
    return Column(children: [
      Expanded(flex: 1, child: Container(),),
      Padding(padding: EdgeInsets.symmetric(horizontal: 32), child:
        Text(message ?? '', textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18)),
      ),
      Expanded(flex: 2, child: Container(),),
    ],);
  }

  // Surveys

  Widget _buildSurveysSection() {
    String title = Localization().getStringEx('panel.event2.setup.survey.survey.title', 'SURVEY');
    title = "SURVEY";
    return Padding(padding: Event2CreatePanel.sectionPadding, child:
      Semantics(container: true, child:
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(flex: 1, child:
            Padding(padding: EdgeInsets.only(right: 8), child:
              Wrap(children: [
                Event2CreatePanel.buildSectionTitleWidget(title),
              ]),
            ),
          ),
          Expanded(flex: 3, child:
            _surveysDropdownWidget
          ),
        ]),
      ),

      /*Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Wrap(children: [Event2CreatePanel.buildSectionTitleWidget(title)])),
          Expanded(child: _surveysDropdownWidget)
        ]),
      ])*/
    );
  }

  Widget get _surveysDropdownWidget =>
    Container(decoration: Event2CreatePanel.dropdownButtonDecoration, child:
    Padding(padding: EdgeInsets.only(left: 12, right: 8), child:
      DropdownButtonHideUnderline(child:
        DropdownButton<Survey?>(
          icon: Styles().images?.getImage('chevron-down'),
          isExpanded: true,
          value: _survey,
          style: Styles().textStyles?.getTextStyle("panel.create_event.dropdown_button.title.regular"),
          hint: Text((_survey != null) ? (_survey?.displayTitle ?? '') : nullSurveyTitle),
          items: _buildSurveyDropDownItems(),
          onChanged: _onSurveyChanged
        ),
      ),
    ),
  );


  List<DropdownMenuItem<Survey?>>? _buildSurveyDropDownItems() {
    List<DropdownMenuItem<Survey?>> items = <DropdownMenuItem<Survey?>>[];
    items.add(DropdownMenuItem<Survey?>(value: null, child:
      Text(nullSurveyTitle),
    ));
    if (_surveys != null) {
      for (Survey survey in _surveys!) {
        items.add(DropdownMenuItem<Survey?>(value: survey, child:
          Text(survey.displayTitle ?? '')
        ));
      }
    }
    return items;
  }

  void _onSurveyChanged(Survey? survey) {
    Analytics().logSelect(target: "Survey: ${(survey != null) ? survey.title : 'null'}");
    if ((_survey != survey) && mounted) {
      setState(() {
        _survey = survey;
      });
      _checkModified();
      //TBD: Preview selected survey
    }
  }

  String get nullSurveyTitle => Localization().getStringEx('panel.event2.setup.survey.no_survey.title', '---');

  // Hours

  Widget _buildHoursSection() => Visibility(visible: (_survey != null), child:
    Padding(padding: Event2CreatePanel.sectionPadding, child:
      Row(children: [
        Flexible(flex: 3, child:
          Event2CreatePanel.buildSectionTitleWidget(Localization().getStringEx('panel.event2.setup.survey.hours.title', 'How many hours after the event ends before sending this survey to attendees?'), maxLines: null)
        ),
        Flexible(flex: 1, child:
          Padding(padding: EdgeInsets.only(left: 6), child:
            Event2CreatePanel.buildTextEditWidget(_hoursController, keyboardType: TextInputType.number, maxLines: 1)
          )
        )
      ])
    )
  );


  // HeaderBar

  bool get _isEditing => StringUtils.isNotEmpty(widget.event?.id);

  PreferredSizeWidget get _headerBar => HeaderBar(
    title: Localization().getStringEx('panel.event2.setup.survey.header.title', 'Event Follow-Up Survey'),
    onLeading: _onHeaderBarBack,
    actions: _headerBarActions,
  );

  List<Widget>? get _headerBarActions {
    if (_updatingSurvey) {
      return [Event2CreatePanel.buildHeaderBarActionProgress()];
    }
    else if (_isEditing && _modified) {
      return [Event2CreatePanel.buildHeaderBarActionButton(
        title: Localization().getStringEx('dialog.apply.title', 'Apply'),
        onTap: _onHeaderBarApply,
      )];
    }
    else {
      return null;
    }
  }

  void _checkModified() {
    if (_isEditing && mounted) {
      
      bool modified = (_survey?.id != _initialSurveyId) ||
        (_hoursController.text != _initialHours);

      if (_modified != modified) {
        setState(() {
          _modified = modified;
        });
      }
    }
  }

  Event2SurveyDetails _buildSurveyDetail() => Event2SurveyDetails(
    surveyId: _survey?.id,
    hoursAfterEvent: Event2CreatePanel.textFieldIntValue(_hoursController),
  );

  bool _checkSurveyDetails(Event2SurveyDetails surveyDetails) {
    if ((_survey?.id != null) && ((surveyDetails.hoursAfterEvent == null) || ((surveyDetails.hoursAfterEvent ?? 0) < 0))) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.event2.setup.survey.hours.invalid.msg', 'Please, fill valid non-negative number for hours.'));
      return false;
    }
    return true;
  }

  void _updateEventSurveyDetails(Event2SurveyDetails? surveyDetails) {
    if (_isEditing && (_updatingSurvey != true)) {
      setState(() {
        _updatingSurvey = true;
      });
      Events2().updateEventSurveyDetails(widget.event?.id ?? '', surveyDetails).then((result) {
        if (mounted) {
          setState(() {
            _updatingSurvey = false;
          });
        }

        if (result is Event2) {
          Navigator.of(context).pop(result);
        }
        else {
          Event2Popup.showErrorResult(context, result);
        }

      });
    }
  }

  void _onHeaderBarApply() {
    Analytics().logSelect(target: 'HeaderBar: Apply');
    Event2SurveyDetails surveyDetails = _buildSurveyDetail();
    if (_checkSurveyDetails(surveyDetails)) {
      _updateEventSurveyDetails(surveyDetails);
    }
  }

  void _onHeaderBarBack() {
    Analytics().logSelect(target: 'HeaderBar: Back');
    if (_isEditing) {
      Navigator.of(context).pop(null);
    }
    else {
      Event2SurveyDetails surveyDetails = _buildSurveyDetail();
      if (_checkSurveyDetails(surveyDetails)) {
        Navigator.of(context).pop(surveyDetails);
      }
    }
  }
}

extension SurveyExt on Survey {
  String? get displayTitle {
    if (StringUtils.isNotEmpty(title)) {
      return title;
    }
    else if (StringUtils.isNotEmpty(id)) {
      return id;
    }
    else {
      return null;
    }
  }
}