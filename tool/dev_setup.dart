#!/usr/bin/env dart

/// Development setup script for Frappe OAuth2 Flutter SDK
/// 
/// This script helps with common development tasks:
/// - Running code generation
/// - Running tests
/// - Checking code quality
/// - Building the project

import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    printUsage();
    return;
  }

  final command = args[0];
  
  switch (command) {
    case 'setup':
      await setup();
      break;
    case 'generate':
      await generateCode();
      break;
    case 'test':
      await runTests();
      break;
    case 'lint':
      await runLint();
      break;
    case 'build':
      await buildProject();
      break;
    case 'clean':
      await cleanProject();
      break;
    default:
      print('Unknown command: $command');
      printUsage();
  }
}

void printUsage() {
  print('''
Frappe OAuth2 Flutter SDK Development Tool

Usage: dart tool/dev_setup.dart <command>

Commands:
  setup     - Initial project setup (pub get, generate code)
  generate  - Run code generation (build_runner)
  test      - Run all tests
  lint      - Run linter and format code
  build     - Build the project for all platforms
  clean     - Clean build artifacts
''');
}

Future<void> setup() async {
  print('🚀 Setting up Frappe OAuth2 Flutter SDK development environment...');
  
  await runCommand('flutter', ['pub', 'get']);
  await runCommand('dart', ['pub', 'get'], workingDirectory: 'example');
  await generateCode();
  
  print('✅ Setup complete!');
}

Future<void> generateCode() async {
  print('🔄 Running code generation...');
  await runCommand('dart', ['run', 'build_runner', 'build', '--delete-conflicting-outputs']);
  print('✅ Code generation complete!');
}

Future<void> runTests() async {
  print('🧪 Running tests...');
  await runCommand('flutter', ['test']);
  print('✅ Tests complete!');
}

Future<void> runLint() async {
  print('🔍 Running linter...');
  await runCommand('dart', ['format', '.']);
  await runCommand('flutter', ['analyze']);
  print('✅ Linting complete!');
}

Future<void> buildProject() async {
  print('🏗️ Building project...');
  await runCommand('flutter', ['build', 'apk', '--debug'], workingDirectory: 'example');
  print('✅ Build complete!');
}

Future<void> cleanProject() async {
  print('🧹 Cleaning project...');
  await runCommand('flutter', ['clean']);
  await runCommand('flutter', ['clean'], workingDirectory: 'example');
  print('✅ Clean complete!');
}

Future<void> runCommand(
  String command, 
  List<String> args, {
  String? workingDirectory,
}) async {
  print('Running: $command ${args.join(' ')}');
  
  final result = await Process.run(
    command,
    args,
    workingDirectory: workingDirectory,
  );
  
  if (result.exitCode != 0) {
    print('❌ Command failed with exit code ${result.exitCode}');
    print('stdout: ${result.stdout}');
    print('stderr: ${result.stderr}');
    exit(result.exitCode);
  }
  
  if (result.stdout.toString().isNotEmpty) {
    print(result.stdout);
  }
}
