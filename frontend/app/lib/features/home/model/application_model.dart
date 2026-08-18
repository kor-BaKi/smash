class ApplicationFormInfo {
  final int id;
  final bool isActive;
  final String? startDate;
  final String? endDate;
  final List<QuestionInfo> questions;

  ApplicationFormInfo({
    required this.id,
    required this.isActive,
    this.startDate,
    this.endDate,
    required this.questions,
  });

  factory ApplicationFormInfo.fromJson(Map<String, dynamic> json) {
    return ApplicationFormInfo(
      id: json['id'],
      isActive: json['isActive'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      questions: (json['questions'] as List)
          .map((e) => QuestionInfo.fromJson(e))
          .toList(),
    );
  }
}

class QuestionInfo {
  final int id;
  final String content;
  final String questionType;
  final bool isRequired;
  final int orderIndex;

  QuestionInfo({
    required this.id,
    required this.content,
    required this.questionType,
    required this.isRequired,
    required this.orderIndex,
  });

  factory QuestionInfo.fromJson(Map<String, dynamic> json) {
    return QuestionInfo(
      id: json['id'],
      content: json['content'],
      questionType: json['questionType'],
      isRequired: json['isRequired'],
      orderIndex: json['orderIndex'],
    );
  }
}

class ApplicationInfo {
  final int id;
  final String name;
  final String studentNo;
  final String department;
  final String phone;
  final String availabilities;
  final String status;
  final String? memo;
  final String createdAt;
  final List<AnswerInfo>? answers;

  ApplicationInfo({
    required this.id,
    required this.name,
    required this.studentNo,
    required this.department,
    required this.phone,
    required this.availabilities,
    required this.status,
    this.memo,
    required this.createdAt,
    this.answers,
  });

  factory ApplicationInfo.fromJson(Map<String, dynamic> json) {
    return ApplicationInfo(
      id: json['id'],
      name: json['name'],
      studentNo: json['studentNo'],
      department: json['department'],
      phone: json['phone'],
      availabilities: json['availabilities'] ?? '',
      status: json['status'],
      memo: json['memo'],
      createdAt: json['createdAt'],
      answers: json['answers'] != null
          ? (json['answers'] as List)
                .map((e) => AnswerInfo.fromJson(e))
                .toList()
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return '미처리';
      case 'ACCEPTED':
        return '합격';
      case 'REJECTED':
        return '불합격';
      default:
        return status;
    }
  }

  String get availabilitiesFormatted {
    if (availabilities.isEmpty) return '-';
    final dayMap = {
      'MON': '월',
      'TUE': '화',
      'WED': '수',
      'THU': '목',
      'FRI': '금',
    };
    final slotMap = {'SLOT_13_15': '1-3시', 'SLOT_15_17': '3-5시'};
    return availabilities
        .split(',')
        .map((pair) {
          final parts = pair.split(':');
          return '${dayMap[parts[0]] ?? parts[0]} ${slotMap[parts[1]] ?? parts[1]}';
        })
        .join(', ');
  }
}

class AnswerInfo {
  final int questionId;
  final String questionContent;
  final String answer;

  AnswerInfo({
    required this.questionId,
    required this.questionContent,
    required this.answer,
  });

  factory AnswerInfo.fromJson(Map<String, dynamic> json) {
    return AnswerInfo(
      questionId: json['questionId'],
      questionContent: json['questionContent'],
      answer: json['answer'],
    );
  }
}
