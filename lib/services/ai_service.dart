class AIService {
  Future<String> sendPrompt({
    required String prompt,
    required String role,
  }) async {
    // Later this will call a real AI API.
    await Future.delayed(const Duration(milliseconds: 700));

    return 'This is a placeholder AI response for $role. Real AI integration will be added later.';
  }

  Future<String> generateReport({
    required String target,
    required String reportType,
  }) async {
    // Later this will generate real AI reports.
    await Future.delayed(const Duration(milliseconds: 700));

    return 'Generated $reportType for $target. This is only a placeholder report.';
  }

  Future<String> analyzePerformance({
    required String target,
  }) async {
    // Later this will analyze attendance, marks, and assignments.
    await Future.delayed(const Duration(milliseconds: 700));

    return '$target has a good academic level, but attendance and assignment consistency should be monitored.';
  }
}