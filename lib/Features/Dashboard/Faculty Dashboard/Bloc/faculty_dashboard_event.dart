sealed class FacultyDashboardEvent {
  const FacultyDashboardEvent();
}

/// Loads (or reloads) the three stat cards.
class FacultyDashboardLoadRequested extends FacultyDashboardEvent {
  const FacultyDashboardLoadRequested();
}

/// Loads the user's quick links.
class QuickLinksLoadRequested extends FacultyDashboardEvent {
  const QuickLinksLoadRequested();
}

/// Deletes a quick link by id.
class QuickLinkDeleteRequested extends FacultyDashboardEvent {
  const QuickLinkDeleteRequested(this.id);

  final int id;
}

/// Adds a quick link for the given menuUniqueId.
class QuickLinkAddRequested extends FacultyDashboardEvent {
  const QuickLinkAddRequested(this.menuUniqueId);

  final int menuUniqueId;
}