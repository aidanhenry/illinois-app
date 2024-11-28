import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/ext/Event2.dart';

class Event2SetupSuperEventPanel extends StatefulWidget{
  final Event2? event;
  final List<Event2>? subEvents;

  const Event2SetupSuperEventPanel({super.key, this.event, this.subEvents});

  @override
  State<StatefulWidget> createState() => Event2SetupSuperEventState();

  static Widget buildTextEditWidget(TextEditingController controller,
      {TextInputType? keyboardType, int? maxLines = 1, EdgeInsetsGeometry padding = const EdgeInsets.all(0), void Function()? onChanged}) {
    return TextField(
        controller: controller,
        decoration: InputDecoration(
            hintText: 'Search your events by the title or description',
            border: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors.lightGray, width: 1), borderRadius: BorderRadius.circular(8)),
            contentPadding: padding),
        // style: EventDetailsPanel.textEditStyle,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: (onChanged != null) ? ((_) => onChanged) : null);
  }

  static Widget buildSectionTitleWidget(String title, {bool enabled = true, int? maxLines}) {
    return Text(title, style: (enabled ? TextStyle() : TextStyle()),maxLines: maxLines);
  }
}
//TBD Notifications for events updated - reload content
class Event2SetupSuperEventState extends State<Event2SetupSuperEventPanel> {
  final TextEditingController _subEventController = TextEditingController();

  String? _searchText;
  List<Event2>? _initialSubEvents;

  List<Event2>? _subEvents;
  List<Event2>? _subEventCandidates;
  Client? _loadCandidatesClient;

  bool _applying = false;

  @override
  void initState() {
    _initialSubEvents = widget.subEvents;
    _subEvents = _initialSubEvents != null ? List.from(_initialSubEvents!) : null;
    _subEventController.text = _searchText ?? '';
    _subEventController.addListener(_loadSubEventCandidates);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(CollectionUtils.isEmpty(_subEvents)){
        _loadSubEvents(init: true);
      }
      _loadSubEventCandidates();
    });
    super.initState();
  }

  @override
  void dispose() {
    _subEventController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.event2.detail.super_event.header.title', 'Super Event Settings'), actions: _headerBarActions,),
      body: _buildContent(),
      backgroundColor: Styles().colors.white,
    );
  }

  Widget _buildContent() =>
      SingleChildScrollView(child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildDescriptionWidget(
                text: 'Set and manage this event as a multi-event “super event.” After creating one or more related events, you can nest those events as sub-events within a super event (e.g., sessions in a conference, performances in a festival).'
            ),
            Padding(padding: EdgeInsets.only(bottom: 16), child: Event2SetupSuperEventPanel.buildSectionTitleWidget('SUB-EVENT(s)')),
            _buildSubEventsSection(_subEvents,
                emptyMsg: 'This event is not linked to any sub-events. Please see below.',
                showUnlink: true),
            Padding(padding: EdgeInsets.only(top: 12), child:
            Container(decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFF717273), width: 1))
            ), padding: EdgeInsets.only(top: 12, left: 16, right: 16)
            )),
            Padding(padding: EdgeInsets.only(bottom: 16), child: Event2SetupSuperEventPanel.buildSectionTitleWidget('LINK EVENT(s)')),
            _buildSubeventSelectionSection(),
            _buildSubEventsSection(_subEventCandidates,
                emptyMsg:  'You currently have no upcoming events. To link and create sub-events within a super event, please first create your sub-events as basic events.',
                showLink: true, ),
          ])
        ));

  Widget _buildDescriptionWidget({required String text}) =>
    Row(children: [
      Expanded(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              maxLines: 8,
              style: Styles().textStyles.getTextStyle("widget.description.regular")))
    ]);

  Widget _buildSubEventsSection(events, {bool showLink = false, bool showUnlink = false, String? emptyMsg}) {
    Widget resultWidget;
    if (CollectionUtils.isEmpty(events)) {
      return _buildDescriptionWidget(text: emptyMsg ?? "");
    } else {
      List<Widget> eventsWidgetList = [];
      events!.forEach((event) {
        eventsWidgetList.add(Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: _EventCard(key: GlobalKey(),
                event: event,
                showLink: showLink,
                showUnlink: showUnlink,
                onTapLink: _onLinkEvent,
                onTapUnlink: _onUnlinkEvent
            )
        ));
      });
      resultWidget = Column(crossAxisAlignment: CrossAxisAlignment.center, children: eventsWidgetList);
    }
    return resultWidget;
  }

  Widget _buildSubeventSelectionSection() => Event2CreatePanel.buildSectionWidget(
    body: Event2SetupSuperEventPanel.buildTextEditWidget(_subEventController, keyboardType: TextInputType.text),
  );

//
  void _loadSubEventCandidates() {
    final text = _subEventController.text;
    if(_searchText?.compareTo(text) != 0) {
      Client client = Client();

      _loadCandidatesClient?.close();
      setStateIfMounted((){
        _searchText = text;
        _loadCandidatesClient = client;
      });

      print('subevent title search: $text (${text.characters.length})');
      _asyncLoadCandidates(client: client)?.then((result) {
          Events2ListResult? listResult = (result is Events2ListResult) ? result : null;
          List<Event2>? candidates = listResult?.events;

          if(identical(_loadCandidatesClient, client)) {
            candidates?.removeWhere(_skipCandidateCondition);
            candidates?.addAll(_additionalCandidates);
            setStateIfMounted(() {
              _subEventCandidates = candidates;
            });
          }
      });
    }
  }

  void _loadSubEvents({bool init = false}) {
    _asyncLoadSubEvents()?.then((loadResult) {
      List<Event2>? events = loadResult?.events;
        setStateIfMounted(() {
          _subEvents = events;

          if(init)
            _initialSubEvents ??=events != null ? List.from(events) : null;
        });
      });
  }

  Future<dynamic>? _asyncLoadCandidates({Client? client}) async => Events2().loadEventsEx( //TBD load in portions: pass offset and limit
    Events2Query(
      searchText: _searchText,
      person:  Event2Person(role: Event2UserRole.admin, identifier: Event2PersonIdentifier(externalId: Auth2().netId))
    ), client: client);

  Future<Events2ListResult?>? _asyncLoadSubEvents() async => _event?.isSuperEvent == true ? Events2().loadEvents(
      Events2Query(grouping:  _event?.linkedEventsGroupingQuery)
  ) : null;

  void _onLinkEvent(Event2 event){
    setStateIfMounted(() {
      _subEventCandidates?.remove(event);
      if(_subEvents == null) {
        _subEvents = [];
      }
      if(_subEvents!.contains(event) == false)
      _subEvents!.add(event);
    });
  }

  void _onUnlinkEvent(Event2 event){
    setStateIfMounted(() {
      if(_subEventCandidates?.contains(event) == false)
        _subEventCandidates?.add(event);
      _subEvents!.remove(event);
    });
  }

  void _onApply(){
    setStateIfMounted(() => _applying = true);
    Event2SuperEventsController(superEvent:_event, existingSubEvents: _initialSubEvents).updateWith(subEventsSelection: _subEvents).then((result){
      setStateIfMounted(() => _applying = false);
    });
  }

  bool _skipCandidateCondition(Event2 candidate) =>
      candidate.id == _event?.id //Exclude this Event
      || candidate.grouping?.type == Event2GroupingType.superEvent //Exclude super events and sub events
      || _subEvents?.contains(candidate) == true; //candidate is already selected but not uploaded yet

  Iterable<Event2> get _additionalCandidates => _initialSubEvents?.where(
          (Event2 event) => _subEvents?.contains(event) == false) ?? [];//candidates that were unlinked but not uploaded yet

  List<Widget>? get _headerBarActions {
    if (_applying) {
      return [Event2CreatePanel.buildHeaderBarActionProgress()];
    }
    else if (_isModified) {
      return [Event2CreatePanel.buildHeaderBarActionButton(
        title: Localization().getStringEx('dialog.apply.title', 'Apply'),
        onTap: _onApply,
      )];
    }
    else {
      return null;
    }
  }

  Event2? get _event => widget.event;
  bool get _isModified => CollectionUtils.equals(_subEvents, _initialSubEvents) == false;
}

class _EventCard extends StatelessWidget{
  final Event2 event;
  final bool? showLink;
  final bool? showUnlink;
  final Function(Event2)? onTapLink;
  final Function(Event2)? onTapUnlink;

  const _EventCard({super.key, required this.event, this.showLink, this.showUnlink, this.onTapLink, this.onTapUnlink});

  @override
  Widget build(BuildContext context) =>
    // TBD consider custom card with link/unlink button like in the Admin App
    Event2Card(event,
        onTap: (){
        if(this.showLink == true)
          this.onTapLink?.call(event);
        else if(showUnlink == true)
          this.onTapUnlink?.call(event);
        });
}

class Event2SuperEventUpdateResult{
    String? error;
    dynamic data;

    Event2SuperEventUpdateResult({String? this.error, this.data});

    static Event2SuperEventUpdateResult fail(String? error) => Event2SuperEventUpdateResult(error: error ?? "error");

    static Event2SuperEventUpdateResult success({dynamic data}) => Event2SuperEventUpdateResult(data: data);

    bool get successful => this.error == null;
}

class Event2SuperEventsController {
  final Event2? superEvent;
  List<Event2>? existingSubEvents;

  Event2SuperEventsController({this.superEvent, this.existingSubEvents});

  Future<Event2SuperEventUpdateResult> updateWith({List<Event2>? subEventsSelection}) async {
    // calculate the difference between existing subEvents and _subEvents
    List<Event2>? addedSubEvents = [];
    List<Event2>? removedSubEvents = [];
    if((subEventsSelection == null) || (subEventsSelection.length == 0)) {
      removedSubEvents = existingSubEvents;
    } else {
        subEventsSelection.forEach((sub) {
        if ((existingSubEvents == null) || !existingSubEvents!.map((event) => (event.id)).contains(sub.id)) {
          addedSubEvents.add(sub);
        }
      });
      existingSubEvents?.forEach((sub) {
        if (!subEventsSelection.map((event)=>(event.id)).contains(sub.id)) {
          removedSubEvents?.add(sub);
        }
      });
    }
    int addedSubEventsCount = 0;
    int removedSubEventsCount = 0;

    // update unlinked subEvents to calendar BB
    if(removedSubEvents != null) {
      for (final removeSubEvent in removedSubEvents) {
        Event2? eventWithoutGrouping = _createUpdatedEventData(removeSubEvent);
        dynamic response = eventWithoutGrouping != null ?  await Events2().updateEvent(eventWithoutGrouping) : null;
        bool succeeded = response is Event2;
        if (!succeeded) {
          // AppAlert.showDialogResult(context, 'Failed to remove sub-event. Response: ${response.body}');
        } else {
          removedSubEventsCount++;
        }
      }
    }
    //TBD Link newly added

    return Event2SuperEventUpdateResult.success();
  }

  Event2? _createUpdatedEventData(Event2 event, {Event2Grouping? grouping, /*bool? published,*/ Event2AuthorizationContext? authorizationContext, Event2Context? event2Context}) {
    if (authorizationContext != null) {
      event.authorizationContext = authorizationContext;
    }
    if (event2Context != null) {
      event.context = event2Context;
    }
    // if (published != null) {
    //   event.published = published;
    // }

    Map<String, dynamic> json = event.toJson();
    if(grouping != null)
      json['grouping'] = grouping.toJson();
    else
      json['grouping'] = "";
    if(!json.containsKey("role") || json["role"] == null) {
      json["role"] = "admin";
    }
    return Event2.fromJson(json);
  }
}