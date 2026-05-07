enum AppEnvironment {
  dev,
  staging,
  prod,
}

class AppEnvironmentConfig {
  const AppEnvironmentConfig._({
    required this.environment,
    required this.appTitle,
  });

  static const String _environmentName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static AppEnvironmentConfig get current {
    return fromName(_environmentName);
  }

  static AppEnvironmentConfig fromName(String name) {
    switch (name.trim().toLowerCase()) {
      case 'dev':
        return dev;
      case 'staging':
        return staging;
      case 'prod':
        return prod;
      default:
        throw ArgumentError.value(
          name,
          'name',
          'Expected one of: dev, staging, prod',
        );
    }
  }

  static const AppEnvironmentConfig dev = AppEnvironmentConfig._(
    environment: AppEnvironment.dev,
    appTitle: 'Smart Mattress Showroom Dev',
  );

  static const AppEnvironmentConfig staging = AppEnvironmentConfig._(
    environment: AppEnvironment.staging,
    appTitle: 'Smart Mattress Showroom Staging',
  );

  static const AppEnvironmentConfig prod = AppEnvironmentConfig._(
    environment: AppEnvironment.prod,
    appTitle: 'Smart Mattress Showroom',
  );

  final AppEnvironment environment;
  final String appTitle;

  String get dartDefineValue {
    return environment.name;
  }
}
