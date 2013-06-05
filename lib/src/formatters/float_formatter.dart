part of sprintf;

class FloatFormatter extends Formatter {
  // TODO: can't rely on '.' being the decimal separator
  static final _number_rx = new RegExp(r'^[\-\+]?(\d+)\.(\d+)$');
  static final _expo_rx = new RegExp(r'^[\-\+]?(\d)\.(\d+)e([\-\+]?\d+)$');
  static final _leading_zeroes_rx = new RegExp(r'^(0*)[1-9]+');

  double _arg;
  List<String> _digits = new List<String>();
  int _exponent = 0;
  int _decimal = 0;
  bool _is_negative = false;
  bool _fraction_is_negative = false;

  FloatFormatter(this._arg, var fmt_type, var options) : super(fmt_type, options) {
    if (_arg < 0) {
      this._is_negative = true;
      _arg = -_arg;
    }

    String arg_str = _arg.toDouble().toString();

    Match m1 = _number_rx.firstMatch(arg_str);
    if (m1 != null) {
      String int_part = m1.group(1);
      String fraction = m1.group(2);

      /*
       * Cases:
       * 1.2345    = 1.2345e0  -> [12345]    e+0 d1  l5
       * 123.45    = 1.2345e2  -> [12345]    e+2 d3  l5
       * 0.12345   = 1.2345e-1 -> [012345]   e-1 d1  l6
       * 0.0012345 = 1.2345e-3 -> [00012345] e-3 d1  l8
       */

      _decimal = int_part.length;
      _digits.addAll(int_part.split(''));
      _digits.addAll(fraction.split(''));

      if (int_part.length == 1) {
        if (int_part == '0') {
          Match leading_zeroes_match = _leading_zeroes_rx.firstMatch(fraction);

          if (leading_zeroes_match != null) {
            int zeroes_count = leading_zeroes_match.group(1).length;
           // print("zeroes_count=${zeroes_count}");
            _exponent = zeroes_count > 0 ? -(zeroes_count + 1) : zeroes_count - 1;
          }
          else {
            _exponent = 0;
          }
        } // else int_part != 0
        else {
          _exponent = 0;
        }
      }
      else {
        _exponent = int_part.length - 1;
      }
    }

    else {
      Match m2 = _expo_rx.firstMatch(arg_str);
      if (m2 != null) {
        String int_part = m2.group(1);
        String fraction = m2.group(2);
        _exponent = int.parse(m2.group(3));

        if (_exponent > 0) {
          int diff = _exponent - fraction.length + 1;
          _decimal = _exponent + 1;
          _digits.addAll(int_part.split(''));
          _digits.addAll(fraction.split(''));
          _digits.addAll(Formatter.get_padding(diff, '0').split(''));
        }
        else {
          int diff = int_part.length - _exponent - 1;
          _decimal = int_part.length;
          _digits.addAll(Formatter.get_padding(diff, '0').split(''));
          _digits.addAll(int_part.split(''));
          _digits.addAll(fraction.split(''));
        }


      } // else something wrong
    }
    //print("arg_str=${arg_str}");
    //print("decimal=${_decimal}, exp=${_exponent}, digits=${_digits}");
  }

  String toString() {
    String ret = '';

    if (options['add_space'] && options['sign'] == '' && _arg >= 0) {
      options['sign'] = ' ';
    }

    if ((_arg as num).isInfinite) {
      if (_arg.isNegative) {
        options['sign'] = '-';
      }

      ret = 'inf';
      options['padding_char'] = ' ';
    }

    if ((_arg as num).isNaN) {
      ret = 'nan';
      options['padding_char'] = ' ';
    }

    if (options['precision'] == -1) {
      options['precision'] = 6; // TODO: make this configurable
    }
    else if (fmt_type == 'g' && options['precision'] == 0) {
      options['precision'] = 1;
    }

    if (_arg is num) {
      if (_is_negative) {
        options['sign'] = '-';
      }

      if (fmt_type == 'e') {
        ret = asExponential(options['precision'], remove_trailing_zeros : false);
      }
      else if (fmt_type == 'f') {
        ret = asFixed(options['precision'], remove_trailing_zeros : false);
      }
      else { // type == g
        int _exp = _exponent;
        var sig_digs = options['precision'];
       // print("${_exp} ${sig_digs}");
        if (-4 <= _exp && _exp < options['precision']) {
          sig_digs -= _decimal;
          num precision = max(options['precision'] - 1 - _exp, sig_digs);

          ret = asFixed(precision, remove_trailing_zeros : !options['alternate_form']);
        }
        else {
          ret = asExponential(options['precision'] - 1, remove_trailing_zeros : !options['alternate_form']);
        }
      }
    }

    var min_chars = options['width'];
    num str_len = ret.length + options['sign'].length;
    String padding = '';

    if (min_chars > str_len) {
      if (options['padding_char'] == '0' && !options['left_align']) {
        padding = Formatter.get_padding(min_chars - str_len, '0');
      }
      else {
        padding = Formatter.get_padding(min_chars - str_len, ' ');
      }
    }

    if (options['left_align']) {
      ret ="${options['sign']}${ret}${padding}";
    }
    else if (options['padding_char'] == '0') {
      ret = "${options['sign']}${padding}${ret}";
    }
    else {
      ret = "${padding}${options['sign']}${ret}";
    }

    if (options['is_upper']) {
      ret = ret.toUpperCase();
    }

    return ret;
  }

  String asFixed(int precision, {bool remove_trailing_zeros : true}) {
    String ret = _digits.sublist(0, _decimal).fold('', (i,e) => "${i}${e}");
    int offset = _decimal;
    int extra_zeroes = precision - (_digits.length - offset);

    if (!remove_trailing_zeros) {
      if (extra_zeroes > 0) {
        _digits.addAll(Formatter.get_padding(extra_zeroes, '0').split(''));
      }
      List<String> trailing_digits =  _digits.sublist(offset, offset + precision);

      var trailing_zeroes = trailing_digits.fold('', (i,e) => "${i}${e}");
            
      ret = "${ret}${new NumberFormat().symbols.DECIMAL_SEP}${trailing_zeroes}";
    }

    return ret;
  }

  String asExponential(int precision, {bool remove_trailing_zeros : true}) {
    int offset = _decimal - _exponent;
    String ret = "${_digits[offset-1]}.";


    int extra_zeroes = precision  - (_digits.length - offset);

    if (extra_zeroes > 0) {
      _digits.addAll(Formatter.get_padding(extra_zeroes, '0').split(''));
    }
    //print ("(${offset}, ${precision})${_digits}");
    List<String> trailing_digits =  _digits.sublist(offset, offset + precision);
   // print ("trailing_digits=${trailing_digits}");
    String _exp_str = _exponent.abs().toString();

    if (_exponent < 10 && _exponent > -10) {
      _exp_str = "0${_exp_str}";
    }

    _exp_str = (_exponent < 0) ? "e-${_exp_str}" : "e+${_exp_str}";

    if (remove_trailing_zeros) {
      int nzeroes = 0;
      for (int i = trailing_digits.length - 1; i > 0; i--) {
        if (trailing_digits[i] == '0') {
          nzeroes++;
        }
        else {
          break;
        }
      }

      trailing_digits = trailing_digits.sublist(0, trailing_digits.length - nzeroes);
    }

    ret = trailing_digits.fold(ret, (i, e) => "${i}${e}");
    ret = "${ret}${_exp_str}";

    return ret;
  }
}