import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/networking/api_service.dart';
import '/bootstrap/extensions.dart';
import '/resources/pages/home_page.dart';

class LoginPage extends NyStatefulWidget {
  static RouteView path = ("/login", (_) => LoginPage());

  LoginPage({super.key}) : super(child: () => _LoginPageState());
}

class _LoginPageState extends NyPage<LoginPage> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword     = true;
  String? _errorMessage;

  @override
  get init => () {};

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Color _iconColor(BuildContext context) => NyColor.resolveColor(
        context,
        light: Colors.grey.shade600,
        dark: Colors.grey.shade400,
      )!;

  Future<void> _onLogin() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Email and password are required');
      return;
    }

    setState(() => _errorMessage = null);

    await lockRelease('login', perform: () async {
      final response = await api<ApiService>(
        (service) => service.login(email, password),
      );

      if (response == null) {
        setState(() => _errorMessage = 'Connection failed. Check your network.');
        return;
      }

      if (response['error'] != null) {
        setState(() => _errorMessage = response['error'] ?? 'Login failed');
        return;
      }

      final staff  = response['user'];
      final tokens = response['tokens'];

      await Auth.set((_) => {
        'access_token':  tokens['access_token'],
        'refresh_token': tokens['refresh_token'],
        'staff': staff,
      });

      showToastSuccess(
        title: 'Welcome back',
        description: '${staff['firstname']} ${staff['lastname']}',
      );

      routeTo(HomePage.path);
    });
  }

  @override
  Widget view(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.general.background,
      appBar: AppBar(
        backgroundColor: context.color.appBar.background,
        foregroundColor: context.color.appBar.content,
        title: const Text('Sign In'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Title
              Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.color.general.content,
              )),
              const SizedBox(height: 8),
              Text('Sign in to your Wasnaker account', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.color.general.primaryAccent,
              )),

              const SizedBox(height: 40),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NyColor.resolveColor(context,
                        light: Colors.red.shade50,
                        dark: const Color(0xFF3D1515)),
                    border: Border.all(
                      color: NyColor.resolveColor(context,
                          light: Colors.red.shade200,
                          dark: Colors.red.shade900)!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: NyColor.resolveColor(context,
                          light: Colors.red.shade700,
                          dark: Colors.red.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: TextStyle(color: context.color.general.content),
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, color: _iconColor(context)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onLogin(),
                style: TextStyle(color: context.color.general.content),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outlined, color: _iconColor(context)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: _iconColor(context),
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 32),

              // Login button
              isLocked('login')
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _onLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.color.general.primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
