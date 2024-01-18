
import 'package:flutter/material.dart';
import 'package:illinois/model/DeviceCalendar.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/device_calendar.dart' as rokwire;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:device_calendar/device_calendar.dart';

class DeviceCalendar extends rokwire.DeviceCalendar implements NotificationsListener {

  // Singletone Factory

  @protected
  DeviceCalendar.internal() : super.internal();

  factory DeviceCalendar() => ((rokwire.DeviceCalendar.instance is DeviceCalendar) ? (rokwire.DeviceCalendar.instance as DeviceCalendar) : (rokwire.DeviceCalendar.instance = DeviceCalendar.internal()));

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoriteChanged
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if(name == Auth2UserPrefs.notifyFavoriteChanged){
      _processFavorite(param);
    }
  }

  void _processFavorite(dynamic event) {
    DeviceCalendarEvent? deviceCalendarEvent = Storage().calendarEnabledToAutoSave == true ? DeviceCalendarEvent.from(event) : null;
    if(deviceCalendarEvent==null)
      return;

    //TBD: Prompt
    if (Auth2().isFavorite(event)) {
      placeEvent(deviceCalendarEvent);
    }
    else {
      deleteEvent(deviceCalendarEvent);
    }
  }

  @protected
  void onCreateOrUpdateEventSucceeded(Result<String>? createEventResult) {
    AppToast.show(Localization().getStringEx('logic.calendar.create_event_succeeded', 'Event added to calendar.'));
  }

  @override
  void onCreateOrUpdateEventFailed(Result<String>? createEventResult) {
    AppToast.show(createEventResult?.data ?? createEventResult?.errors.toString() ?? Localization().getStringEx('logic.calendar.create_event_failed', 'Failed to create event.'));
  }

  @override
  void onRequestPermissionFailed() {
    AppToast.show(Localization().getStringEx('logic.calendar.permission_denied', 'Unable to save event to calendar. Permissions not granted.'));
  }
}
