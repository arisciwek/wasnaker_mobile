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
              });
          },
        );

  @override
  Map<Type, Interceptor> get interceptors => {
        ...super.interceptors,
        BearerAuthInterceptor: BearerAuthInterceptor(),
      };

  // ── Auth — apps module ────────────────────────────────────────────────────

  Future<dynamic> login(String email, String password) async {
    return await network(
      request: (request) => request.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      ),
    );
  }

  Future<dynamic> me() async {
    return await network(
      request: (request) => request.get('/auth/me'),
    );
  }

  Future<dynamic> refresh(String refreshToken) async {
    return await network(
      request: (request) => request.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      ),
    );
  }
}
