import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

class FamilyCalendarPage extends StatefulWidget {
  final String familyId;

  const FamilyCalendarPage({
    super.key,
    required this.familyId,
  });

  @override
  State<FamilyCalendarPage> createState() =>
      _FamilyCalendarPageState();
}

class _FamilyCalendarPageState
    extends State<FamilyCalendarPage> {

  final supabase =
      Supabase.instance.client;

  DateTime focusedDay =
      DateTime.now();

  DateTime? selectedDay =
      DateTime.now();

  List<Map<String, dynamic>> events = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    loadEvents();
  }

  Future<void> loadEvents() async {
    try {
      final response =
          await supabase
              .from('Calendar_Events')
              .select()
              .eq(
                'family_id',
                widget.familyId,
              )
              .order(
                'start_at',
                ascending: true,
              );

      if (!mounted) return;

      setState(() {
        events =
            List<Map<String, dynamic>>
                .from(response);

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load calendar: $e',
          ),
        ),
      );
    }
  }

  List<Map<String, dynamic>>
      eventsForDay(DateTime day) {

    return events.where((event) {
      final eventDate =
          DateTime.parse(
        event['start_at'].toString(),
      ).toLocal();

      return eventDate.year ==
              day.year &&
          eventDate.month ==
              day.month &&
          eventDate.day ==
              day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents =
        selectedDay == null
            ? <Map<String, dynamic>>[]
            : eventsForDay(
                selectedDay!,
              );

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Family Calendar',
        ),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () async {
          final result =
              await context.push<bool>(
            '/family/${widget.familyId}/calendar/add-event',
          );

          if (result == true) {
            loadEvents();
          }
        },
        icon:
            const Icon(
          Icons.add,
        ),
        label:
            const Text(
          'Add Event',
        ),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Column(
              children: [
                TableCalendar(
                  firstDay:
                      DateTime.utc(
                    2000,
                    1,
                    1,
                  ),

                  lastDay:
                      DateTime.utc(
                    2100,
                    12,
                    31,
                  ),

                  focusedDay:
                      focusedDay,

                  selectedDayPredicate:
                      (day) {
                    return isSameDay(
                      selectedDay,
                      day,
                    );
                  },

                  onDaySelected:
                      (
                    newSelectedDay,
                    newFocusedDay,
                  ) {
                    setState(() {
                      selectedDay =
                          newSelectedDay;

                      focusedDay =
                          newFocusedDay;
                    });
                  },

                  onPageChanged:
                      (newFocusedDay) {
                    focusedDay =
                        newFocusedDay;
                  },

                  eventLoader:
                      eventsForDay,

                  calendarStyle:
                      const CalendarStyle(
                    markerDecoration:
                        BoxDecoration(
                      shape:
                          BoxShape.circle,
                    ),
                  ),

                  headerStyle:
                      const HeaderStyle(
                    formatButtonVisible:
                        false,

                    titleCentered:
                        true,
                  ),
                ),

                const Divider(),

                Expanded(
                  child:
                      selectedEvents.isEmpty
                          ? const Center(
                              child: Text(
                                'No events for this day.',
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.all(
                                16,
                              ),
                              itemCount:
                                  selectedEvents
                                      .length,
                              itemBuilder:
                                  (
                                context,
                                index,
                              ) {
                                final event =
                                    selectedEvents[
                                        index];

                                return buildEventCard(
                                  event,
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }

  Widget buildEventCard(
    Map<String, dynamic> event,
  ) {
    final start =
        DateTime.parse(
      event['start_at'].toString(),
    ).toLocal();

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        leading:
            Icon(
          eventIcon(
            event['event_type'],
          ),
        ),

        title:
            Text(
          event['title'] ?? '',
        ),

        subtitle:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              formatTime(start),
            ),

            if (event['location'] !=
                null)
              Text(
                event['location'],
              ),
          ],
        ),

        onTap: () {
          // Later:
          // open event details/edit page
        },
      ),
    );
  }

  IconData eventIcon(dynamic type) {
    switch (type) {
      case 'daycare':
        return Icons.child_care;

      case 'sports':
        return Icons.sports_soccer;

      case 'birthday':
        return Icons.cake;

      case 'school':
        return Icons.school;

      case 'medical':
        return Icons.medical_services;

      default:
        return Icons.event;
    }
  }

  String formatTime(
    DateTime date,
  ) {
    final hour =
        date.hour > 12
            ? date.hour - 12
            : date.hour == 0
                ? 12
                : date.hour;

    final minute =
        date.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    final period =
        date.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $period';
  }
}