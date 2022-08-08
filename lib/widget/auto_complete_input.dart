// import 'package:flutter/material.dart';
//
// void main() => runApp(const AutocompleteExampleApp());
//
// class AutocompleteExampleApp extends StatelessWidget {
//   const AutocompleteExampleApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('Autocomplete Basic User'),
//         ),
//         body: const Center(
//           child: AutocompleteBasicUserExample(),
//         ),
//       ),
//     );
//   }
// }
//
// @immutable
// class User {
//   const User({
//     required this.email,
//     required this.name,
//   });
//
//   final String email;
//   final String name;
//
//   @override
//   String toString() {
//     return '$name, $email';
//   }
//
//   @override
//   bool operator ==(Object other) {
//     if (other.runtimeType != runtimeType) {
//       return false;
//     }
//     return other is User && other.name == name && other.email == email;
//   }
//
//   @override
//   int get hashCode => Object.hash(email, name);
// }
