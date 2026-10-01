enum AppEnvironment {
  dev,
  test,
  prod;

  static AppEnvironment fromDefine() {
    const value = String.fromEnvironment(
      'FINAPP_ENV',
      defaultValue: 'dev',
    );

    return switch (value.toLowerCase()) {
      'prod' || 'production' => AppEnvironment.prod,
      'test' => AppEnvironment.test,
      _ => AppEnvironment.dev,
    };
  }

  bool get isProduction => this == AppEnvironment.prod;
}
