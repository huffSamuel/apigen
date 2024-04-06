
class Tuple<T1, T2> {
  final T1? a;
  final T2? b;

  Tuple({this.a, this.b});

  factory Tuple.fromJson(
    FromJsonFn<T1> a,
    FromJsonFn<T2> b,
    Map<String, dynamic> json,
  ) {
    try {
      return Tuple(a: a(json));
    } catch (_) {}

    try {
      return Tuple(b: b(json));
    } catch (_) {}

    return Tuple();
  }
}

typedef FromJsonFn<T> = T Function(Map<String, dynamic> json);
