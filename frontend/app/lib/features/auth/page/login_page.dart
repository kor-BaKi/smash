// import 'package:app/features/auth/provider/auth_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// class LoginPage extends ConsumerStatefulWidget {
//   const LoginPage({super.key});
//
//   @override
//   ConsumerState<LoginPage> createState() => _LoginPageState();
// }
//
// class _LoginPageState extends ConsumerState<LoginPage> {
//   final _studentNoController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//
//   @override
//   void dispose() {
//     _studentNoController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _login() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     await ref.read(authProvider.notifier).login(
//       _studentNoController.text.trim(),
//       _passwordController.text,
//     );
//   }
//   @override
//   Widget build(BuildContext context) {
//     final authState = ref.watch(authProvider);
//
//     return Scaffold(
//       body: ,
//     );
//   }
// }
