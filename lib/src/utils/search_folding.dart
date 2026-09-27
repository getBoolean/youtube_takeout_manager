/// Lowercases [text] and drops U+FE0F (emoji presentation selector) so `❤️`
/// and `❤` match each other. Apply to both the query and the searched text.
String foldForSearch(String text) {
  final lower = text.toLowerCase();
  return lower.contains('\u{FE0F}') ? lower.replaceAll('\u{FE0F}', '') : lower;
}
