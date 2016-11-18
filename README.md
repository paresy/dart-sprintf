dart-sprintf
============

Dart implementation of sprintf.

[![Build Status](https://travis-ci.org/Naddiseo/dart-sprintf.svg?branch=master)](https://travis-ci.org/Naddiseo/dart-sprintf/)

Getting Started
---------------

Add the following to your **pubspec.yaml**:

```
dependencies:
	sprintf:
		path: extern/sprintf
```

then run **pub install**.

Next, import dart-sprintf and the required dependencies:

```
import 'package:intl/intl.dart';
import 'package:intl/intl_browser.dart';
import 'package:sprintf/sprintf.dart';
```

### Example
```
import 'package:intl/intl.dart';
import 'package:intl/intl_browser.dart';
import 'package:sprintf/sprintf.dart';

void main() {
	findSystemLocale().then((String locale) {
		print(sprintf("%04i", [-42]));
		print(sprintf("%s %s", ["Hello", "World"]));
		print(sprintf("%#04x", [10]));
	}
}
```

```
-042
Hello World
0x0a
```

Limitations
-----------

* Negative numbers are wrapped as 64bit ints when formatted as hex or octal.
* %F should not be locale aware

Differences to C's printf

* When using fixed point printing of numbers with large exponents, C introduces errors after 20 decimal places. Dart-printf will just print 0s.