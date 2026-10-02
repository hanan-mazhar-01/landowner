/// Every route path in one place.
abstract final class Routes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgot = '/forgot-password';
  static const locationSetup = '/location-setup';

  static const home = '/home';
  static const properties = '/properties';
  static const finance = '/finance';
  static const more = '/more';

  static const notifications = '/notifications';
  static const notificationSettings = '/notifications/settings';
  static const ai = '/ai';

  static const tenants = '/tenants';
  static const maintenance = '/maintenance';
  static const documents = '/documents';
  static const calendar = '/calendar';
  static const payments = '/finance/payments';
  static const income = '/finance/income';
  static const expenses = '/finance/expenses';
  static const cashFlow = '/finance/cash-flow';
  static const transactions = '/finance/transactions';
  static const reports = '/finance/reports';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const changePassword = '/profile/password';
  static const deleteAccount = '/profile/delete';
  static const privacyPolicy = '/privacy-policy';
  static const termsOfService = '/terms-of-service';

  static String property(String id) => '/properties/$id';
  static String tenant(String leaseId) => '/tenants/$leaseId';
  static String payment(String chargeId) => '/finance/payments/$chargeId';
  static String maintenanceItem(String id) => '/maintenance/$id';
  static String document(String id) => '/documents/$id';
  static String report(String type) => '/finance/reports/$type';

  /// List routes scoped to one property.
  static String forProperty(String base, String propertyId) =>
      Uri(path: base, queryParameters: {'property': propertyId}).toString();
  static String reminder(String id) => '/reminders/${Uri.encodeComponent(id)}';
  static String overdue(String chargeId) => '/overdue/$chargeId';

  /// Entry forms: property, lease, income, expense, tenant, maintenance,
  /// document, reminder. Optional pre-selected property / record to edit.
  static String add(String form, {String? propertyId, String? editId}) {
    final q = {'property': ?propertyId, 'edit': ?editId};
    return Uri(path: '/add/$form', queryParameters: q.isEmpty ? null : q).toString();
  }
}
