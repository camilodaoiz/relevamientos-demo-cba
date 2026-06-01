// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

void downloadText(
  String content,
  String filename, {
  String mime = 'text/plain;charset=utf-8',
}) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body!.children.add(anchor);
  anchor.click();
  html.document.body!.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}
