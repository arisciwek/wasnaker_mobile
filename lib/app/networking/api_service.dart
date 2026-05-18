import 'package:wasnaker_core/wasnaker_core.dart';
import '/bootstrap/decoders.dart';
import 'dio/interceptors/bearer_auth_interceptor.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ApiService extends WasnakerApiService {
  ApiService()
      : super(
          decoders: modelDecoders,
          useNetworkLogger: true,
          baseOptions: (BaseOptions options) {
            return options
              ..headers.addAll({
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'X-Api-Key': getEnv('API_KEY', defaultValue: ''),
              });
          },
        );

  @override
  Map<Type, Interceptor> get interceptors => {
        ...super.interceptors,
        BearerAuthInterceptor: BearerAuthInterceptor(),
      };

  // ── Auth endpoints ────────────────────────────────────────────────────────

  Future<dynamic> login(String email, String password) async {
    return await network(
      request: (request) => request.post(
        '/surveyors/auth/login',
        data: {'email': email, 'password': password},
      ),
    );
  }

  Future<dynamic> me() async {
    return await network(
      request: (request) => request.get('/surveyors/auth/me'),
    );
  }

  Future<dynamic> logout() async {
    return await network(
      request: (request) => request.post('/surveyors/auth/logout'),
    );
  }
}
