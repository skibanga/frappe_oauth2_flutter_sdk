library;

// Core client
export 'frappe_oauth_client_simple.dart' hide FrappeConfigurationException;

// Models
export 'models/auth_result.dart';
export 'models/oauth_config.dart';
export 'models/token_response.dart';
export 'models/user_info.dart';

// Exceptions
export 'exceptions/frappe_auth_exception.dart';

// Services (for advanced usage)
export 'services/network_service.dart';

// Utilities
export 'utils/url_builder.dart';
export 'utils/validation_utils.dart';

import 'frappe_oauth2_flutter_sdk_platform_interface.dart';

class FrappeOauth2FlutterSdk {
  Future<String?> getPlatformVersion() {
    return FrappeOauth2FlutterSdkPlatform.instance.getPlatformVersion();
  }
}
