import test from 'ava';
import { parse } from '..';

test('parse simple SOQL to AST', (t) => {
  const parsed = parse('SELECT Id, Name FROM Account');
  t.true(typeof parsed === 'object');
});

test('parse SOQL with where clause', (t) => {
  let parsed = parse(`
    SELECT Id, Name FROM Account
    WHERE Name LIKE 'A%' AND Type = 'A' OR Type != 'B'
  `);
  console.log(JSON.stringify(parsed, null, 4));
  t.true(typeof parsed === 'object');
  parsed = parse(`
    SELECT Id, Name FROM Account
    WHERE Name LIKE 'A%' AND (Type = 'A' OR Type != 'B')
  `);
  console.log(JSON.stringify(parsed, null, 4));
  t.true(typeof parsed === 'object');
});

test('parse complex SOQL', (t) => {
  const soql = `
    SELECT
      Id, Name, Owner.Id, toLabel(StageName),
      (SELECT Id, Contact.Id, Contact.Name, format(Contact.Account.NumberOfEmployees)
       FROM OpportunityContactRoles
       LIMIT 10)
    FROM Opportunity
    USING SCOPE Mine
    WHERE
      Account.Name LIKE 'O\\'reilly%'
    OR
      (NOT (
        CALENDAR_MONTH(CreatedDate) = 10
      AND
        CreatedDate > 2015-12-31
      ))
    AND
      Owner.Name = 'Hello'
    OR
      Probability > 99.5
    ORDER BY
      Account.Type DESC NULLS LAST,
      CreatedDate
  `;
  const ast = parse(soql);
  t.deepEqual(ast, {
    type: 'Query',
    fields: [{
      type: 'FieldReference',
      path: ['Id'],
    }, {
      type: 'FieldReference',
      path: ['Name'],
    }, {
      type: 'FieldReference',
      path: ['Owner', 'Id'],
    }, {
      type: 'FunctionCall',
      name: 'toLabel',
      arguments: [{
        type: 'FieldReference',
        path: ['StageName'],
      }],
    }, {
      type: 'Query',
      fields: [{
        type: 'FieldReference',
        path: ['Id'],
      }, {
        type: 'FieldReference',
        path: ['Contact', 'Id'],
      }, {
        type: 'FieldReference',
        path: ['Contact', 'Name'],
      }, {
        type: 'FunctionCall',
        name: 'format',
        arguments: [{
          type: 'FieldReference',
          path: ['Contact', 'Account', 'NumberOfEmployees'],
        }],
      }],
      object: 'OpportunityContactRoles',
      limit: 10,
    }],
    object: 'Opportunity',
    scope: 'Mine',
    condition: {
      type: 'LogicalCondition',
      operator: 'OR',
      left: {
        type: 'LogicalCondition',
        operator: 'OR',
        left: {
          type: 'ComparisonCondition',
          operator: 'LIKE',
          field: {
            type: 'FieldReference',
            path: ['Account', 'Name'],
          },
          value: {
            type: 'string',
            value: "O'reilly%",
          },
        },
        right: {
          type: 'LogicalCondition',
          operator: 'AND',
          left: {
            type: 'NegateCondition',
            operator: 'NOT',
            condition: {
              type: 'LogicalCondition',
              operator: 'AND',
              left: {
                type: 'ComparisonCondition',
                operator: '=',
                field: {
                  type: 'FunctionCall',
                  name: 'CALENDAR_MONTH',
                  arguments: [{
                    type: 'FieldReference',
                    path: ['CreatedDate'],
                  }],
                },
                value: {
                  type: 'number',
                  value: 10,
                },
              },
              right: {
                type: 'ComparisonCondition',
                operator: '>',
                field: {
                  type: 'FieldReference',
                  path: ['CreatedDate'],
                },
                value: {
                  type: 'date',
                  value: '2015-12-31',
                },
              },
              parentheses: true,
            },
            parentheses: true,
          },
          right: {
            type: 'ComparisonCondition',
            operator: '=',
            field: {
              type: 'FieldReference',
              path: ['Owner', 'Name'],
            },
            value: {
              type: 'string',
              value: 'Hello',
            },
          }
        },
      },
      right: {
        type: 'ComparisonCondition',
        operator: '>',
        field: {
          type: 'FieldReference',
          path: ['Probability'],
        },
        value: {
          type: 'number',
          value: 99.5,
        },
      },
    },
    sort: [{
      field: {
        type: 'FieldReference',
        path: ['Account', 'Type'],
      },
      direction: 'DESC',
      nullOrder: 'LAST',
    }, {
      field: {
        type: 'FieldReference',
        path: ['CreatedDate'],
      },
      direction: null,
      nullOrder: null,
    }],
  });

});
