import 'package:crm_pos/utils/error_text.dart';
import 'package:crm_pos/utils/phone.dart';
import 'package:crm_pos/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('errorText', () {
    test('strips the Exception prefix', () {
      expect(errorText(Exception('Name taken')), 'Name taken');
    });

    test('strips every occurrence, like the original replaceAll', () {
      expect(
        errorText(Exception('Exception: nested')),
        'nested',
      );
    });

    test('leaves other error types untouched', () {
      expect(errorText(StateError('bad')), 'Bad state: bad');
      expect(errorText('plain string'), 'plain string');
    });
  });

  test('digitsOnly', () {
    expect(digitsOnly('+961 70 123 456'), '96170123456');
    expect(digitsOnly('(03) 123-456'), '03123456');
    expect(digitsOnly(''), '');
    expect(digitsOnly('abc'), '');
  });

  group('validateEmailBasic', () {
    test('requires a value', () {
      expect(validateEmailBasic(null), 'Please enter your email');
      expect(validateEmailBasic('   '), 'Please enter your email');
    });

    test('only checks for @ (untrimmed)', () {
      expect(validateEmailBasic('nope'), 'Please enter a valid email');
      expect(validateEmailBasic('a@b'), isNull);
      expect(validateEmailBasic(' a@b '), isNull);
    });
  });

  group('validateNewPassword', () {
    test('requires a value of at least 6 characters', () {
      expect(validateNewPassword(null), 'Please enter a password');
      expect(validateNewPassword(''), 'Please enter a password');
      expect(validateNewPassword('12345'),
          'Password must be at least 6 characters');
      expect(validateNewPassword('123456'), isNull);
      expect(validateNewPassword('      '), isNull); // spaces count
    });
  });

  group('validatePasswordConfirmation', () {
    test('requires a matching value', () {
      expect(validatePasswordConfirmation(null, 'secret1'),
          'Please confirm your password');
      expect(validatePasswordConfirmation('', 'secret1'),
          'Please confirm your password');
      expect(validatePasswordConfirmation('secret2', 'secret1'),
          'Passwords do not match');
      expect(validatePasswordConfirmation('secret1', 'secret1'), isNull);
    });
  });
}
