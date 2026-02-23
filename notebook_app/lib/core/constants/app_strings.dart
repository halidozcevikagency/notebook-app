/// i18n (uluslararasılaştırma) için metin sabitleri
/// İleride ARB dosyalarına dönüştürülecek
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'Notebook';
  static const String appTagline = 'Your thoughts, beautifully organized';

  // Auth
  static const String signIn = 'Sign In';
  static const String signUp = 'Create Account';
  static const String signOut = 'Sign Out';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String fullName = 'Full Name';
  static const String continueWithGoogle = 'Continue with Google';
  static const String continueWithGitHub = 'Continue with GitHub';
  static const String continueWithApple = 'Continue with Apple';
  static const String forgotPassword = 'Forgot Password?';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String dontHaveAccount = "Don't have an account?";

  // Dashboard
  static const String allNotes = 'All Notes';
  static const String pinned = 'Pinned';
  static const String recent = 'Recent';
  static const String favorites = 'Favorites';
  static const String trash = 'Trash';
  static const String newNote = 'New Note';
  static const String newWorkspace = 'New Workspace';
  static const String newFolder = 'New Folder';
  static const String search = 'Search notes...';
  static const String workspaces = 'Workspaces';
  static const String folders = 'Folders';
  static const String tags = 'Tags';

  // Editor
  static const String untitled = 'Untitled';
  static const String startWriting = 'Start writing...';
  static const String saving = 'Saving...';
  static const String saved = 'Saved';
  static const String typeSlashForCommands = "Type '/' for commands";

  // AI Features
  static const String aiSummarize = 'Summarize';
  static const String aiSpellCheck = 'Spell Check';
  static const String aiTranslate = 'Translate';
  static const String aiVoiceToText = 'Voice to Text';
  static const String processing = 'Processing...';

  // Share
  static const String share = 'Share';
  static const String copyLink = 'Copy Link';
  static const String shareWithPassword = 'Protected Link';
  static const String inviteByEmail = 'Invite by Email';
  static const String viewOnly = 'View Only';
  static const String canEdit = 'Can Edit';

  // Profile
  static const String profile = 'Profile';
  static const String settings = 'Settings';
  static const String deleteAccount = 'Delete Account';
  static const String deleteAccountConfirm =
      'Are you sure? This action is irreversible and will delete all your notes.';

  // General
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String delete = 'Delete';
  static const String save = 'Save';
  static const String edit = 'Edit';
  static const String rename = 'Rename';
  static const String moveToTrash = 'Move to Trash';
  static const String restore = 'Restore';
  static const String emptyTrash = 'Empty Trash';
  static const String exportAsPdf = 'Export as PDF';
  static const String exportAsMarkdown = 'Export as Markdown';
  static const String pin = 'Pin Note';
  static const String unpin = 'Unpin Note';
  static const String noNotes = 'No notes yet';
  static const String startYourFirstNote = 'Create your first note';
  static const String loading = 'Loading...';
  static const String error = 'Something went wrong';
  static const String retry = 'Retry';
  static const String linkCopied = 'Link copied to clipboard!';
}
