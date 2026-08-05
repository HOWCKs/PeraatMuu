class SessionModel {
  final String consoleId;
  final String gameName;
  final int timeSec;
  final DateTime startTime;

  SessionModel({
    required this.consoleId,
    required this.gameName,
    required this.timeSec,
    required this.startTime,
  });

  factory SessionModel.fromJson(Map<String, dynamic> j) => SessionModel(
    consoleId: j['consoleId'],
    gameName: j['gameName'],
    timeSec: j['timeSec'],
    startTime: DateTime.parse(j['startTime']),
  );

  Map<String, dynamic> toJson() => {
    'consoleId': consoleId,
    'gameName': gameName,
    'timeSec': timeSec,
    'startTime': startTime.toIso8601String(),
  };
}

class UserProgress {
  String user;
  List<SessionModel> sessions;
  Map<String, int> consoleTimes; // consoleId -> total sec
  int totalTimeSec;

  UserProgress({
    this.user = 'lan_user',
    List<SessionModel>? sessions,
    Map<String, int>? consoleTimes,
    this.totalTimeSec = 0,
  })  : sessions = sessions ?? [],
        consoleTimes = consoleTimes ?? {};

  void addSession(SessionModel s) {
    sessions.add(s);
    totalTimeSec += s.timeSec;
    consoleTimes[s.consoleId] = (consoleTimes[s.consoleId] ?? 0) + s.timeSec;
  }

  factory UserProgress.fromJson(Map<String, dynamic> j) {
    final p = UserProgress(
      user: j['user'] ?? 'lan_user',
      totalTimeSec: j['totalTimeSec'] ?? 0,
      consoleTimes: Map<String, int>.from(j['consoleTimes'] ?? {}),
    );
    if (j['sessions'] != null) {
      p.sessions = (j['sessions'] as List).map((e) => SessionModel.fromJson(e)).toList();
    }
    return p;
  }

  Map<String, dynamic> toJson() => {
    'user': user,
    'totalTimeSec': totalTimeSec,
    'consoleTimes': consoleTimes,
    'sessions': sessions.map((s) => s.toJson()).toList(),
  };
}
