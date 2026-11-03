class ApiEndPoints {
  ApiEndPoints._();

  static const String login = '/auth/login';
  static const String requestReset = '/auth/request-reset';
  static const String verifyOtp = '/auth/verify-otp';
  static const String fetchUserContact = '/auth/fetch-user-contact';
  static const String confirmReset = '/auth/confirm-reset';
  static const String getProfile = '/adminuser/get-profile';

  // Faculty dashboard : Attendance Mraking
  static const String academicSession = '/academicsession';
  static const String allotmentsAll = '/allotments/all';
  static const String preferenceSelectionsAll = '/prefrenceselectionfinalall';
  static const String timeTable = '/time-table';
  static const String attendanceAll = '/get-all-attendance';
  static const String attendanceSessions = '/attendance-sessions';
  static const String daySequence = '/day-sequence';
  static const String timeTableByTeacherAndDay ='/time-table/by-teacher-and-day';
  static const String attendanceStatusAll = '/attendance-status/all';
  static const String filterStudents = '/subject-preference/filter-students';
  static const String topicsBySubject = '/topics/by-subject';
  static const String attendanceDetails = '/attendance-details';
  static const String markAttendance = '/mark-attendance';

  //Lecture Overview
  static const String dashboardSummary = '/api/teacher/dashboard-summary';
  
  //Syllabus endpoints
  static const String getFacultySubjectsByUser = '/teacher/subjects/by-user';
  static const String getUnitsBySubject = '/units';
  static const String createUnit = '/unit/create';
  static const String updateUnit = '/unit/update';
  static const String getTopicsByUnit = '/topics';
  static const String createTopic = '/topic/create';
  static const String updateTopic = '/topic/update';
  static const String getAllTopics = '/get-all-topics';

  //Profile
  static const String updateUser = '/admin/update';
  static const String changeProfile = '/auth/change-profile';
  static const String deleteProfile = '/delete-profile';
  static const String changePassword = '/auth/change-password';

    // Quick Links
  static const String quickLinks = '/quick-links';
  static String quickLinksByUser(int userId) => '/user/$userId';
  static String deleteQuickLink(int id) => '/$id';

  // Assessment & Marks Entry
  static const String allTests = '/api/test/all/testmaster';
  static String testDistributions(int allotmentId) => '/api/test/all-distributions/$allotmentId';
  static const String allAssignments = '/api/elearning-assignments/all';
  static String assignmentSubmissions(int assignmentId) => '/api/elearning-assignments/$assignmentId/submissions';

}
