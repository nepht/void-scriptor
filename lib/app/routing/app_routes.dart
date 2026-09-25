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
  static const aiImageGenerator = '/ai/image-generator';
  static const aiVideoGenerator = '/ai/video-generator';
  static const aiComposer = '/ai/composer';
  static const aiHistory = '/ai/history';
  static const aiGallery = '/ai/gallery';
  static const aiProviders = '/ai/providers';
  static const donation = '/donation';

  /// Route global kanonik Account & Cloud Center (115.3, product spec).
  static const accountCloud = '/account/cloud-center';

  /// Alias lama yang tetap diterima dan di-redirect ke [accountCloud].
  static const accountCloudLegacy = '/account-cloud';
  static const settings = '/settings';
  static const contentCapabilities = '/content-capabilities';
  static const workspace = '/workspace';
  static const studio = '/studio';
  static const assets = '/assets';
  static const references = '/references';
  static const bible = '/bible';
  static const creatures = '/creatures';
  static const vehicles = '/vehicles';
  static const props = '/props';
  static const cinematicProduction = '/cinematic-production';
  static const productionValidation = '/production-validation';
  static const projectDiagnostics = '/project-diagnostics';

  /// Storage location settings (145.38 Core settings UI; wiring Task 4).
  static const storageLocations = '/settings/storage-locations';
  static const projectRepair = '/project-repair';
  static const projectBackups = '/project-backups';
  static const projectExport = '/project-export';
  static const projectImport = '/project-import';
  static const projectStorage = '/project-storage';
  static const projectCache = '/project-cache';
  static const projectTrash = '/project-trash';
  static const collaborationComments = '/collaboration/comments';
  static const security = '/security';
  static const securityLock = '/security/lock';
  static const plugins = '/plugins';
  static const render = '/render';
  static const animation = '/animation';
  static const audio = '/audio';
  static const virtualProduction = '/virtual-production';
  static const publishing = '/publishing';
  static const enterpriseStudio = '/enterprise-studio';
  static const knowledge = '/knowledge';
  static const agents = '/agents';
  static const studioCommandCenter = '/studio-command-center';
  static const creativeOs = '/creative-os';
  static const xrStudio = '/xr-studio';
  static const metaverse = '/metaverse';

  static const foundationRoutes = <String, String>{
    'SPLASH': splash,
    'ONBOARDING': onboarding,
    'AUTHENTICATION': authentication,
    'DASHBOARD': dashboard,
    'PROJECTS': projects,
    'AI STUDIO': aiStudio,
    'DONATION': donation,
    'ACCOUNT & CLOUD CENTER': accountCloud,
    'WORKSPACE': workspace,
    'COLLABORATION COMMENTS': collaborationComments,
  };

  /// Legacy aliases kept as thin redirects to their canonical Settings routes.
  static const foundationAliases = <String, String>{
    '/theme-settings': settings,
  };
}
