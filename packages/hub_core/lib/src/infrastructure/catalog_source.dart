/// Catalog published by the website.
final defaultCatalogUri = Uri.parse(
  'https://dynamotivation.com/v1/catalog.json/',
);

/// The catalog address: `--catalog-url=<uri>` if given (e.g. the local site
/// preview `http://127.0.0.1:1111/v1/catalog.json/`), else [defaultCatalogUri].
Uri catalogUriFromArgs(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--catalog-url=')) {
      return Uri.parse(arg.substring('--catalog-url='.length));
    }
  }
  return defaultCatalogUri;
}
