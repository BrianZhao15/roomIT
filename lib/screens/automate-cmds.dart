import 'dart:io';

Future<void> runAdbTarCommand() async {
  try {
    ProcessResult result = await Process.run(
      'adb',
      [
        'shell',
        'run-as',
        'room.it.room_it',
        'tar',
        '-cf',
        '-',
        '-C',
        '/data/data/room.it.room_it/app_flutter',
        '.'
      ],
    );

    final framesFile = File('frames.tar');
    await framesFile.writeAsBytes(result.stdout);

    if(result.exitCode == 0) {
      print('Command ran successfully');
    } else {
      print('Command failed: ${result.stderr}');
    }
  } catch (e) {
    print('Error running adb command: $e');
  }
}