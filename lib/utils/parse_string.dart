String? noneNullOrEmptyString(String? value) {
  if (value == null || value.isEmpty) return null;
  return value;
}
