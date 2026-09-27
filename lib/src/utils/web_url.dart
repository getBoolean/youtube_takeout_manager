/// Whether [url] is an http or https URL.
bool isWebUrl(String url) {
  final scheme = Uri.tryParse(url)?.scheme;
  return scheme == 'https' || scheme == 'http';
}
