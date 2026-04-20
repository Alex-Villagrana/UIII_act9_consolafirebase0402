import 'dart:io';

void main() async {
  print('=============================================');
  print('  Agente para enviar a GitHub (Dart) ');
  print('=============================================\n');

  // 1. Pedir el link del repositorio
  String? repoLink;
  while (repoLink == null || repoLink.trim().isEmpty) {
    stdout.write('1. Ingresa el link del nuevo repositorio de GitHub: ');
    repoLink = stdin.readLineSync();
  }

  // 2. Pedir mensaje del commit
  String? commitMessage;
  while (commitMessage == null || commitMessage.trim().isEmpty) {
    stdout.write('2. Ingresa el mensaje del commit: ');
    commitMessage = stdin.readLineSync();
  }

  // 3. Establecer rama main por default o pedir otra
  stdout.write('3. Nombre de la rama (presiona Enter para usar "main" por defecto): ');
  String branchName = stdin.readLineSync() ?? '';
  if (branchName.trim().isEmpty) {
    branchName = 'main';
  }

  print('\nIniciando proceso de subida a la rama "$branchName" en "$repoLink"...\n');

  // Ejecutar comandos git
  try {
    // git init
    print('>> git init');
    var initResult = await Process.run('git', ['init']);
    if (initResult.exitCode != 0) {
      print('Advertencia / Info en git init: ${initResult.stdout} ${initResult.stderr}');
    }

    // git add .
    print('>> git add .');
    var addResult = await Process.run('git', ['add', '.']);
    if (addResult.exitCode != 0) {
      print('Error al ejecutar git add: ${addResult.stderr}');
      return;
    }

    // git commit
    print('>> git commit -m "$commitMessage"');
    var commitResult = await Process.run('git', ['commit', '-m', commitMessage]);
    if (commitResult.exitCode != 0 && !commitResult.stdout.toString().contains('nothing to commit')) {
      print('Nota sobre commit (posiblemente no había cambios o falló): \n${commitResult.stdout}\n${commitResult.stderr}');
    }

    // git branch -M
    print('>> git branch -M $branchName');
    var branchResult = await Process.run('git', ['branch', '-M', branchName]);
    if (branchResult.exitCode != 0) {
      print('Error al cambiar de rama: ${branchResult.stderr}');
      return;
    }

    // git remote add origin
    print('>> Configurando remote origin...');
    // Se intenta remover si es que ya existe un origin configurado antes
    await Process.run('git', ['remote', 'remove', 'origin']);
    var remoteResult = await Process.run('git', ['remote', 'add', 'origin', repoLink.trim()]);
    if (remoteResult.exitCode != 0) {
      print('Error al agregar el remote origin: ${remoteResult.stderr}');
      return;
    }

    // git push -u origin branchName
    print('>> git push -u origin $branchName');
    var pushProcess = await Process.start('git', ['push', '-u', 'origin', branchName]);

    // Redirigir la salida del comando push a la terminal actual
    stdout.addStream(pushProcess.stdout);
    stderr.addStream(pushProcess.stderr);

    var pushExitCode = await pushProcess.exitCode;

    if (pushExitCode == 0) {
      print('\n======================================================');
      print(' ✅ ¡Repositorio subido a GitHub exitosamente! ✅ ');
      print('======================================================');
    } else {
      print('\n❌ Hubo un error al hacer git push (código de salida: $pushExitCode). Verifica tu conexión, repositorio y permisos. ❌');
    }

  } catch (e) {
    print('Ocurrió un error inesperado al ejecutar los comandos: $e');
  }
}
