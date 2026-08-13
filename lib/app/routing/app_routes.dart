abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  static const onboarding = '/onboarding';
  static const authentication = '/authentication';
  static const dashboard = '/dashboard';
  static const projects = '/projects';
  static const createProject = '/projects/create';
  static const studioProject = '/studio/:projectId';
  static const aiStudio = '/ai-studio';
  static const aiComposer = '/ai/composer';
  static const aiHistory = '/ai/history';
  static const aiGallery = '/ai/gallery';
  static const aiProviders = '/ai/providers';
  static const donation = '/donation';
  static const workspace = '/workspace';
  static const studio = '/studio';
  static const assets = '/assets';
  static const references = '/references';
  static const bible = '/bible';

  static const foundationRoutes = <String, String>{
    'SPLASH': splash,
    'ONBOARDING': onboarding,
    'AUTHENTICATION': authentication,
    'DASHBOARD': dashboard,
    'PROJECTS': projects,
    'AI STUDIO': aiStudio,
    'DONATION': donation,
    'WORKSPACE': workspace,
  };
}
