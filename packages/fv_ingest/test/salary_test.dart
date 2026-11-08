import 'package:fv_core/fv_core.dart';
import 'package:fv_ingest/fv_ingest.dart';
import 'package:test/test.dart';

void main() {
  group('salaryFromText', () {
    test('reads a range after a pay word', () {
      expect(
        salaryFromText('The base salary range for this role is \$150,000 - \$190,000 plus equity.'),
        const Salary(min: 150000, max: 190000, currency: 'USD'),
      );
      expect(
        salaryFromText('Salary: €60.000–€75.000 brutto'),
        const Salary(min: 60000, max: 75000, currency: 'EUR'),
      );
      expect(
        salaryFromText('Compensation: 90-110K EUR'),
        const Salary(min: 90000, max: 110000, currency: 'EUR'),
      );
    });

    test('reads the period when stated, and needs no pay word then', () {
      expect(
        salaryFromText('We offer PHP 80,000 to 120,000 per month.'),
        const Salary(min: 80000, max: 120000, currency: 'PHP', per: PayPeriod.month),
      );
      expect(
        salaryFromText('£450-£550/day inside IR35'),
        const Salary(min: 450, max: 550, currency: 'GBP', per: PayPeriod.day),
      );
      expect(
        salaryFromText('CA\$35 - 38 per hour'),
        const Salary(min: 35, max: 38, currency: 'CAD', per: PayPeriod.hour),
      );
      expect(
        salaryFromText('\$120k-\$150k/yr'),
        const Salary(min: 120000, max: 150000, currency: 'USD', per: PayPeriod.year),
      );
    });

    test('reads the period from the words leading into the range', () {
      expect(
        salaryFromText('The gross monthly salary for this position ranges from 6266€ to 8812€, depending on skills.'),
        const Salary(min: 6266, max: 8812, currency: 'EUR', per: PayPeriod.month),
      );
      expect(
        salaryFromText('Annual base salary: \$180,000 - \$250,000'),
        const Salary(min: 180000, max: 250000, currency: 'USD', per: PayPeriod.year),
      );
    });

    test('a K on the second figure covers the first', () {
      expect(salaryFromText('Salary \$120-150K'), const Salary(min: 120000, max: 150000, currency: 'USD'));
    });

    test('skips money that is not pay', () {
      expect(salaryFromText('We raised \$20-30M in our Series B.'), isNull);
      expect(salaryFromText('Salary aside, a \$1,000 - \$2,000 learning budget.'), isNull);
      expect(salaryFromText('A range of 3-5 years of Flutter experience.'), isNull, reason: 'no currency');
      expect(
        salaryFromText('We have 10,000 - 20,000 USD in monthly ad spend'),
        isNull,
        reason: 'no pay word or period',
      );
      expect(salaryFromText('Try 3-5 builds'), isNull, reason: 'codes are upper case only');
    });

    test('a range stays pay with + bonus or + equity after it', () {
      expect(
        salaryFromText('Salary: \$140,000 - \$160,000 + bonus + equity'),
        const Salary(min: 140000, max: 160000, currency: 'USD'),
      );
    });

    test('says negotiable when the text does', () {
      expect(salaryFromText('Salary: Negotiable'), const Salary.negotiable());
      expect(salaryFromText('The salary is negotiable based on experience.'), const Salary.negotiable());
      expect(salaryFromText('We offer a negotiable salary and remote work.'), const Salary.negotiable());
      expect(salaryFromText('Competitive pay, start date negotiable.'), isNull, reason: 'about the start date');
      expect(salaryFromText('Flutter Engineer, remote'), isNull);
    });

    test('a stated range wins over negotiable', () {
      expect(
        salaryFromText('Salary: \$100,000 - \$120,000, negotiable for the right person'),
        const Salary(min: 100000, max: 120000, currency: 'USD'),
      );
    });

    test('lenient reads a bare range in a Hacker News header', () {
      const header = 'Acme | Senior Flutter Engineer | Remote (US) | \$150k-\$190k';
      expect(salaryFromText(header), isNull);
      expect(salaryFromText(header, lenient: true), const Salary(min: 150000, max: 190000, currency: 'USD'));
    });
  });

  group('ATS pay fields', () {
    test('Greenhouse pay_input_ranges, in cents, period from the title', () {
      expect(
        greenhousePay([
          {'min_cents': 15000000, 'max_cents': 22000000, 'currency_type': 'USD', 'title': 'Base Range'},
        ]),
        const Salary(min: 150000, max: 220000, currency: 'USD'),
      );
      expect(
        greenhousePay([
          {'min_cents': 4500, 'max_cents': 5200, 'currency_type': 'usd', 'title': 'Hourly Range'},
        ]),
        const Salary(min: 45, max: 52, currency: 'USD', per: PayPeriod.hour),
      );
      expect(greenhousePay([]), isNull);
      expect(greenhousePay(null), isNull);
    });

    test('Lever salaryRange', () {
      expect(
        leverPay({'min': 35, 'max': 38, 'currency': 'CAD', 'interval': 'per-hour-wage'}),
        const Salary(min: 35, max: 38, currency: 'CAD', per: PayPeriod.hour),
      );
      expect(
        leverPay({'min': 90000, 'max': 120000, 'currency': 'EUR', 'interval': 'per-year-salary'}),
        const Salary(min: 90000, max: 120000, currency: 'EUR', per: PayPeriod.year),
      );
      expect(leverPay({'currency': 'USD'}), isNull);
    });

    test('Ashby Salary component, not equity', () {
      expect(
        ashbyPay({
          'summaryComponents': [
            {'compensationType': 'EquityCashValue', 'interval': '1 YEAR', 'currencyCode': 'USD'},
            {
              'compensationType': 'Salary',
              'interval': '1 YEAR',
              'currencyCode': 'USD',
              'minValue': 170000,
              'maxValue': 250000,
            },
          ],
        }),
        const Salary(min: 170000, max: 250000, currency: 'USD', per: PayPeriod.year),
      );
      expect(ashbyPay({'summaryComponents': <Object?>[]}), isNull);
      expect(ashbyPay(null), isNull);
    });
  });
}
