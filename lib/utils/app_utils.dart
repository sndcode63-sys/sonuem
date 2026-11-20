String formatNum(num? value) {
  if (value == null) return "0";
  return value % 1 == 0 ? value.toInt().toString() : value.toString();
}
