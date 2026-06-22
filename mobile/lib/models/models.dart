// Dart DTOs mirroring the backend JSON (see frontend/src/types/index.ts).

class AuthResponse {
  final String token;
  final int userId;
  final String email;

  AuthResponse({required this.token, required this.userId, required this.email});

  factory AuthResponse.fromJson(Map<String, dynamic> j) => AuthResponse(
        token: j['token'] as String,
        userId: (j['userId'] as num).toInt(),
        email: j['email'] as String,
      );
}

class Subject {
  final int id;
  final String fullName;
  final String baseName;
  final String lessonType; // LECTURE | LAB | EXERCISE | COMBINED

  Subject({
    required this.id,
    required this.fullName,
    required this.baseName,
    required this.lessonType,
  });

  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
        id: (j['id'] as num).toInt(),
        fullName: j['fullName'] as String? ?? '',
        baseName: j['baseName'] as String? ?? '',
        lessonType: j['lessonType'] as String? ?? 'LECTURE',
      );
}

class Teacher {
  final int id;
  final String? cyrillicName;
  final String? canonicalName;

  Teacher({required this.id, this.cyrillicName, this.canonicalName});

  factory Teacher.fromJson(Map<String, dynamic> j) => Teacher(
        id: (j['id'] as num).toInt(),
        cyrillicName: j['cyrillicName'] as String?,
        canonicalName: j['canonicalName'] as String?,
      );

  String get displayName => cyrillicName ?? canonicalName ?? '';
}

class Classroom {
  final int id;
  final String name;
  final String? shortName;

  Classroom({required this.id, required this.name, this.shortName});

  factory Classroom.fromJson(Map<String, dynamic> j) => Classroom(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String? ?? '',
        shortName: j['shortName'] as String?,
      );
}

class StudyClass {
  final int id;
  final String name;
  final int? year;
  final String? programmeCode;

  StudyClass({required this.id, required this.name, this.year, this.programmeCode});

  factory StudyClass.fromJson(Map<String, dynamic> j) => StudyClass(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String? ?? '',
        year: (j['year'] as num?)?.toInt(),
        programmeCode: j['programmeCode'] as String?,
      );
}

class ScheduleSlot {
  final int id;
  final Subject subject;
  final List<Teacher> teachers;
  final List<StudyClass> studyClasses;
  final Classroom? classroom;
  final int dayOfWeek; // 0=Mon … 4=Fri
  final String startTime; // "HH:mm:ss"
  final String endTime;
  final String editionNumber;

  ScheduleSlot({
    required this.id,
    required this.subject,
    required this.teachers,
    required this.studyClasses,
    required this.classroom,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.editionNumber,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> j) => ScheduleSlot(
        id: (j['id'] as num).toInt(),
        subject: Subject.fromJson(j['subject'] as Map<String, dynamic>),
        teachers: ((j['teachers'] as List?) ?? [])
            .map((e) => Teacher.fromJson(e as Map<String, dynamic>))
            .toList(),
        studyClasses: ((j['studyClasses'] as List?) ?? [])
            .map((e) => StudyClass.fromJson(e as Map<String, dynamic>))
            .toList(),
        classroom: j['classroom'] == null
            ? null
            : Classroom.fromJson(j['classroom'] as Map<String, dynamic>),
        dayOfWeek: (j['dayOfWeek'] as num).toInt(),
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        editionNumber: j['editionNumber'] as String? ?? '',
      );

  /// "HH:mm:ss" -> "HH:mm"
  String get start => startTime.length >= 5 ? startTime.substring(0, 5) : startTime;
  String get end => endTime.length >= 5 ? endTime.substring(0, 5) : endTime;
}

class TimetableFiltersData {
  final List<int> years;
  final List<String> programmes;
  final List<Subject> subjects;
  final List<Teacher> teachers;
  final List<Classroom> classrooms;
  final List<String> editions;
  final String? currentEdition;

  TimetableFiltersData({
    required this.years,
    required this.programmes,
    required this.subjects,
    required this.teachers,
    required this.classrooms,
    required this.editions,
    required this.currentEdition,
  });

  factory TimetableFiltersData.fromJson(Map<String, dynamic> j) => TimetableFiltersData(
        years: ((j['years'] as List?) ?? []).map((e) => (e as num).toInt()).toList(),
        programmes: ((j['programmes'] as List?) ?? []).map((e) => e as String).toList(),
        subjects: ((j['subjects'] as List?) ?? [])
            .map((e) => Subject.fromJson(e as Map<String, dynamic>))
            .toList(),
        teachers: ((j['teachers'] as List?) ?? [])
            .map((e) => Teacher.fromJson(e as Map<String, dynamic>))
            .toList(),
        classrooms: ((j['classrooms'] as List?) ?? [])
            .map((e) => Classroom.fromJson(e as Map<String, dynamic>))
            .toList(),
        editions: ((j['editions'] as List?) ?? []).map((e) => e as String).toList(),
        currentEdition: j['currentEdition'] as String?,
      );
}

/// Local filter state sent to GET /timetable/slots.
class TimetableFilters {
  final int? year;
  final String? programmeCode;
  final int? teacherId;
  final int? subjectId;
  final int? classroomId;
  final String? lessonType;
  final int? dayOfWeek;
  final String? editionNumber;

  const TimetableFilters({
    this.year,
    this.programmeCode,
    this.teacherId,
    this.subjectId,
    this.classroomId,
    this.lessonType,
    this.dayOfWeek,
    this.editionNumber,
  });

  TimetableFilters copyWith({
    int? Function()? year,
    String? Function()? programmeCode,
    int? Function()? teacherId,
    int? Function()? subjectId,
    int? Function()? classroomId,
    String? Function()? lessonType,
    int? Function()? dayOfWeek,
    String? Function()? editionNumber,
  }) {
    return TimetableFilters(
      year: year != null ? year() : this.year,
      programmeCode: programmeCode != null ? programmeCode() : this.programmeCode,
      teacherId: teacherId != null ? teacherId() : this.teacherId,
      subjectId: subjectId != null ? subjectId() : this.subjectId,
      classroomId: classroomId != null ? classroomId() : this.classroomId,
      lessonType: lessonType != null ? lessonType() : this.lessonType,
      dayOfWeek: dayOfWeek != null ? dayOfWeek() : this.dayOfWeek,
      editionNumber: editionNumber != null ? editionNumber() : this.editionNumber,
    );
  }

  bool get isEmpty =>
      year == null &&
      programmeCode == null &&
      teacherId == null &&
      subjectId == null &&
      classroomId == null &&
      lessonType == null &&
      dayOfWeek == null;

  int get activeCount => [
        year,
        programmeCode,
        teacherId,
        subjectId,
        classroomId,
        lessonType,
        dayOfWeek,
      ].where((e) => e != null).length;

  Map<String, String> toQuery() {
    final m = <String, String>{};
    if (year != null) m['year'] = '$year';
    if (programmeCode != null) m['programmeCode'] = programmeCode!;
    if (teacherId != null) m['teacherId'] = '$teacherId';
    if (subjectId != null) m['subjectId'] = '$subjectId';
    if (classroomId != null) m['classroomId'] = '$classroomId';
    if (lessonType != null) m['lessonType'] = lessonType!;
    if (dayOfWeek != null) m['dayOfWeek'] = '$dayOfWeek';
    if (editionNumber != null) m['editionNumber'] = editionNumber!;
    return m;
  }
}

class CustomEntry {
  final int id;
  final String title;
  final String? professor;
  final String entryType; // LECTURE | LAB | EXERCISE | COMBINED
  final int dayOfWeek;
  final String startTime; // "HH:mm:ss"
  final String endTime;
  final String? room;
  final String? color;

  CustomEntry({
    required this.id,
    required this.title,
    required this.professor,
    required this.entryType,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.color,
  });

  factory CustomEntry.fromJson(Map<String, dynamic> j) => CustomEntry(
        id: (j['id'] as num).toInt(),
        title: j['title'] as String? ?? '',
        professor: j['professor'] as String?,
        entryType: j['entryType'] as String? ?? 'LECTURE',
        dayOfWeek: (j['dayOfWeek'] as num).toInt(),
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        room: j['room'] as String?,
        color: j['color'] as String?,
      );

  String get start => startTime.length >= 5 ? startTime.substring(0, 5) : startTime;
  String get end => endTime.length >= 5 ? endTime.substring(0, 5) : endTime;
}

class Exam {
  final int id;
  final String session;
  final String subjectName;
  final String date; // "YYYY-MM-DD"
  final String? startTime;
  final String? endTime;
  final String? rooms;
  final String? note;

  Exam({
    required this.id,
    required this.session,
    required this.subjectName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.rooms,
    required this.note,
  });

  factory Exam.fromJson(Map<String, dynamic> j) => Exam(
        id: (j['id'] as num).toInt(),
        session: j['session'] as String? ?? '',
        subjectName: j['subjectName'] as String? ?? '',
        date: j['date'] as String,
        startTime: j['startTime'] as String?,
        endTime: j['endTime'] as String?,
        rooms: j['rooms'] as String?,
        note: j['note'] as String?,
      );

  String? get start =>
      startTime != null && startTime!.length >= 5 ? startTime!.substring(0, 5) : startTime;
  String? get end =>
      endTime != null && endTime!.length >= 5 ? endTime!.substring(0, 5) : endTime;
}

class ConsultationSlot {
  final int id;
  final Teacher teacher;
  final String date; // "YYYY-MM-DD"
  final String startTime;
  final String endTime;
  final String? room;
  final String? link;
  final String? instructions;
  final int enrolledCount;

  ConsultationSlot({
    required this.id,
    required this.teacher,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.link,
    required this.instructions,
    required this.enrolledCount,
  });

  factory ConsultationSlot.fromJson(Map<String, dynamic> j) => ConsultationSlot(
        id: (j['id'] as num).toInt(),
        teacher: Teacher.fromJson(j['teacher'] as Map<String, dynamic>),
        date: j['date'] as String,
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        room: j['room'] as String?,
        link: j['link'] as String?,
        instructions: j['instructions'] as String?,
        enrolledCount: (j['enrolledCount'] as num?)?.toInt() ?? 0,
      );

  String get start => startTime.length >= 5 ? startTime.substring(0, 5) : startTime;
  String get end => endTime.length >= 5 ? endTime.substring(0, 5) : endTime;
}

class TeacherWithSlots {
  final Teacher teacher;
  final List<ConsultationSlot> slots;

  TeacherWithSlots({required this.teacher, required this.slots});

  factory TeacherWithSlots.fromJson(Map<String, dynamic> j) => TeacherWithSlots(
        teacher: Teacher.fromJson(j['teacher'] as Map<String, dynamic>),
        slots: ((j['slots'] as List?) ?? [])
            .map((e) => ConsultationSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

const List<String> kDayNames = [
  'Понеделник',
  'Вторник',
  'Среда',
  'Четврток',
  'Петок',
];
