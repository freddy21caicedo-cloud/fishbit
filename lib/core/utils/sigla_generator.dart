/// Utilidad para la generacion inteligente y estandarizada de siglas de empresas y sedes acuicolas.
class SiglaGenerator {
  static const Set<String> _stopwords = {
    'de', 'del', 'la', 'las', 'el', 'los', 'y', 'e', 'en', 'para', 'por', 'a',
    'sas', 'ltda', 'sa', 'cia',
  };

  /// Genera una sigla corta en mayusculas a partir de una cadena [rawText].
  static String generate(String rawText, {String fallback = 'PRI', int maxLength = 5}) {
    if (rawText.trim().isEmpty) return fallback;

    // Primero normalizar y remover puntos y comas para que "S.A.S." sea "sas"
    final cleanText = rawText.trim().replaceAll('.', '');
    final normalized = _removeDiacritics(cleanText)
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .toLowerCase();

    final tokens = normalized
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && !_stopwords.contains(t))
        .toList();

    if (tokens.isEmpty) {
      final fallbackTokens = _removeDiacritics(cleanText)
          .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();

      if (fallbackTokens.isEmpty) return fallback;
      return _generateFromTokens(fallbackTokens, maxLength, fallback);
    }

    return _generateFromTokens(tokens, maxLength, fallback);
  }

  static String _generateFromTokens(List<String> tokens, int maxLength, String fallback) {
    if (tokens.length == 1) {
      final word = tokens.first.toUpperCase();
      if (word.length <= 3) return word;
      return word.substring(0, 3);
    }

    final acronym = tokens.map((t) => t[0].toUpperCase()).join();
    if (acronym.length > maxLength) {
      return acronym.substring(0, maxLength);
    }
    return acronym.isNotEmpty ? acronym : fallback;
  }

  static String _removeDiacritics(String str) {
    const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const withoutDia = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    var result = str;
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result;
  }
}
