import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_csv_encoder.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_parser.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/zip_extraction_service.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/own_channel.dart';

Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

const _dir = 'Takeout/YouTube and YouTube Music';
const _channelPath = '$_dir/channels/channel.csv';
const _urlConfigsPath = '$_dir/channels/channel URL configs.csv';

/// As Google Takeout writes it, description spanning lines included.
const _channelCsv =
    'Channel ID,Channel Description (Original),Channel Tag 1,'
    'Channel Title (Original),Channel Visibility\r\n'
    'UCmain,"software developer\n",Minecraft,Boolean,Public\r\n'
    'UCalt,,,"Alt, the second",Public\r\n';

const _urlConfigsCsv =
    'Channel ID,Channel Vanity URL 1 Name\r\n'
    'UCmain,booleandev\r\n';

void main() {
  test("reads the takeout's own channels, titles and vanity names", () {
    final data = parseCsvFiles({
      _channelPath: _bytes(_channelCsv),
      _urlConfigsPath: _bytes(_urlConfigsCsv),
    });

    expect(data.ownChannels, {
      'UCmain': const OwnChannel(
        channelId: 'UCmain',
        title: 'Boolean',
        vanityName: 'booleandev',
      ),
      'UCalt': const OwnChannel(channelId: 'UCalt', title: 'Alt, the second'),
    });
  });

  test('a takeout without channel files has no own channels', () {
    expect(parseCsvFiles(const {}).ownChannels, isEmpty);
  });

  test('a channel file with only a header has no own channels', () {
    final data = parseCsvFiles({
      _channelPath: _bytes('Channel ID,Channel Title (Original)\r\n'),
    });
    expect(data.ownChannels, isEmpty);
  });

  test('own channels survive a save and reload', () {
    final data = parseCsvFiles({
      _channelPath: _bytes(_channelCsv),
      _urlConfigsPath: _bytes(_urlConfigsCsv),
    });

    expect(
      parseCsvFiles(encodeTakeoutCsvs(data)).ownChannels,
      data.ownChannels,
    );
  });

  test('zip extraction keeps the two channel files and no others', () {
    final archive = Archive();
    for (final name in [
      'channel.csv',
      'channel URL configs.csv',
      'channel images.csv',
      'channel page settings.csv',
      'channel feature data.csv',
    ]) {
      archive.addFile(ArchiveFile.string('$_dir/channels/$name', 'x'));
    }
    final zip = ZipEncoder().encodeBytes(archive);

    final files = ZipExtractionService().extractRelevantFiles([zip]);

    expect(
      files.keys,
      unorderedEquals(['0/$_channelPath', '0/$_urlConfigsPath']),
    );
  });
}
