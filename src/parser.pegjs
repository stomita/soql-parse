Query =
  __
  SELECT                 __
  fields:FieldList       __
  object:FromClause      __
  scope:ScopeClause?     __
  condition:WhereClause? __
  group:GroupByClause?   __
  sort:OrderByClause?    __
  limit:LimitClause?     __
  offset:OffsetClause?   __ {
    return Object.assign(
      {
        type: 'Query',
        fields: fields,
        object: object,
      },
      scope ? { scope: scope } : {},
      condition ? { condition: condition } : {},
      group ? { group: group } : {},
      sort ? { sort: sort } : {},
      typeof limit === 'number' ? { limit: limit } : {},
      typeof offset === 'number' ? { offset: offset } : {}
    );
  }

FieldList =
  head:FieldListItem __ COMMA __ tail:FieldList {
    return [head].concat(tail);
  }
/ field:FieldListItem {
    return [field]
  }

FromClause =
  FROM __ object:Identifier {
    return object;
  }

FieldListItem =
  SubQuery
/ FieldExpr

FieldExpr =
  FunctionCall
/ FieldReference

FunctionCall =
  func:Identifier __ LPAREN __ args:FunctionArg* __ RPAREN {
    return {
      type: 'FunctionCall',
      name: func,
      arguments: args,
    };
  }

FunctionArg =
  FieldReference

FieldReference =
  path:FieldPath {
    return {
      type: 'FieldReference',
      path: path,
    };
  }

FieldPath =
  head:Identifier __ DOT __ tail:FieldPath {
    return [head].concat(tail);
  }
/ field:Identifier {
    return [field];
  }

ScopeClause =
  USING __ SCOPE __ scope:FilterScope {
    return scope;
  }

FilterScope =
  "Delegated"i { return 'Delegated'; }
/ "Everything"i { return 'Everything'; }
/ "Mine"i { return 'Mine'; }
/ "My_Territory"i { return 'My_My_Territory'; }
/ "My_Team_Territory"i { return 'My_Team_Territory'; }
/ "Team"i { return 'Team'; }

WhereClause =
  WHERE __ condition: Condition {
    return condition
  }

GroupByClause =
  GROUP __ BY __ {
    return null;
  }

OrderByClause =
  ORDER __ BY __ sort:SortItemList {
    return sort;
  }

SortItemList =
  head:SortItem __ COMMA __ tail:SortItemList {
    return [head].concat(tail);
  }
/ sort:SortItem {
    return [sort];
  }

SortItem =
  field:FieldExpr __ direction:SortDir? __ nullOrder:NullOrder? {
    return {
      field: field,
      direction: direction,
      nullOrder: nullOrder,
    };
  }

SortDir =
  ASC { return "ASC"; }
/ DESC { return "DESC"; }

NullOrder =
  NULLS __ FIRST { return "FIRST"; }
/ NULLS __ LAST { return "LAST"; }

LimitClause =
  LIMIT __ n:Int {
    return parseInt(n, 10);
  }

OffsetClause =
  OFFSET __ n:Int {
    return parseInt(n, 10);
  }

Condition =
  OrCondition

OrCondition =
  LPAREN __ left:Condition __ RPAREN __ OR __ right:OrCondition {
    return {
      type: 'LogicalCondition',
      operator: 'OR',
      left: Object.assign({}, left, { parentheses: true }),
      right: right
    };
  }
/ left:AndCondition __ OR __ right:Condition {
    return {
      type: 'LogicalCondition',
      operator: 'OR',
      left: left,
      right: right
    };
  }
/ AndCondition

AndCondition =
  LPAREN __ left:Condition __ RPAREN __ AND __ right:AndCondition {
    return {
      type: 'LogicalCondition',
      operator: 'AND',
      left: Object.assign({}, left, { parentheses: true }),
      right: right
    };
  }
/ left:NotCondition __ AND __ right:AndCondition {
    return {
      type: 'LogicalCondition',
      operator: 'AND',
      left: left,
      right: right,
    };
  }
/ NotCondition

NotCondition =
  ComparisonCondition
/ NOT __ LPAREN __ condition:Condition __ RPAREN {
    return {
      type: 'NegateCondition',
      operator: 'NOT',
      condition: Object.assign({}, condition, { parentheses: true }),
      parentheses: true
    };
  }
/ NOT __ condition:ComparisonCondition {
    return {
      type: 'NegateCondition',
      operator: 'NOT',
      condition: condition
    };
  }

ComparisonCondition =
  field:FieldExpr __ operator:ComparisonOperator __ value:ComparisonValue {
    return {
      type: 'ComparisonCondition',
      field: field,
      operator: operator,
      value: value,
    };
  }

ComparisonOperator =
  "=" / "!=" / "<" / "<=" / ">" / ">="
/ "LIKE"i { return 'LIKE'; }
/ "IN"i { return 'IN'; }
/ "NOT"i " " __ "IN"i { return 'NOT IN'; }
/ "INCLUDES"i { return 'INCLUDES'; }
/ "EXCLUDES"i { return 'EXCLUDES'; }

ComparisonValue =
  SubQuery
/ Literal

SubQuery =
  LPAREN                 __
  SELECT                 __
  fields:ChildFieldList  __
  object:FromClause      __
  condition:WhereClause? __
  sort:OrderByClause?    __
  limit:LimitClause?     __
  RPAREN {
    return Object.assign(
      {
        type: 'Query',
        fields: fields,
        object: object,
      },
      condition ? { condition: condition } : {},
      sort ? { sort: sort } : {},
      typeof limit === 'number' ? { limit: limit } : {}
    );
  }

ChildFieldList =
  head:ChildFieldListItem __ COMMA __ tail:ChildFieldList {
    return [head].concat(tail);
  }
/ field:ChildFieldListItem {
    return [field]
  }

ChildFieldListItem = FieldExpr

Identifier = [a-zA-Z][0-9a-zA-Z_]* { return text() }

Literal =
  DateLiteral
/ NumberLiteral
/ StringLiteral
/ BooleanLiteral
/ NullLiteral

NumberLiteral =
  n:Number {
    return {
      type: 'number',
      value: n
    }
  }

Number =
  int_:Int frac:Frac exp:Exp __ { return parseFloat(int_ + frac + exp); }
/ int_:Int frac:Frac __         { return parseFloat(int_ + frac); }
/ int_:Int exp:Exp __           { return parseFloat(int_ + exp); }
/ int_:Int __                   { return parseFloat(int_); }

Int
  = digit19:Digit19 digits:Digits { return digit19 + digits; }
  / digit:Digit
  / op:[+-] digits:Digits { return op + digit19 + digits; }
  / op:[+-] digit:Digit { return op + digit; }

Frac
  = "." digits:Digits { return "." + digits; }

Exp
  = e:E digits:Digits { return e + digits; }

Digits
  = digits:Digit+ { return digits.join(""); }

Digit   = [0-9]
Digit19 = [1-9]

HexDigit
  = [0-9a-fA-F]

E
  = e:[eE] sign:[+-]? { return e + (sign !== null ? sign: ''); }

StringLiteral =
  QUOTE ca:(SingleChar*) QUOTE {
    return {
      type: 'string',
      value: ca.join('')
    };
  }


SingleChar =
  [^'\\\0-\x1F\x7f]
/ EscapeChar

EscapeChar =
  "\\'"  { return "'";  }
/ '\\"'  { return '"';  }
/ "\\\\" { return "\\"; }
/ "\\/"  { return "/";  }
/ "\\b"  { return "\b"; }
/ "\\f"  { return "\f"; }
/ "\\n"  { return "\n"; }
/ "\\r"  { return "\r"; }
/ "\\t"  { return "\t"; }
/ "\\u" h1:HexDigit h2:HexDigit h3:HexDigit h4:HexDigit {
  return String.fromCharCode(parseInt("0x" + h1 + h2 + h3 + h4));
}

DateLiteral =
  Digit Digit Digit Digit "-" Digit Digit "-" Digit Digit {
    return {
      type: 'date',
      value: text()
    };
  }

BooleanLiteral =
  TRUE {
    return {
      type: 'boolean',
      value: true
    };
  }
/ FALSE {
  return {
    type: 'boolean',
    value: false
  };
}

NullLiteral =
  NULL {
    return {
      type: 'null',
      value: null
    };
  }

COMMA  = ","
DOT    = "."
LPAREN = "("
RPAREN = ")"
QUOTE  = "'"

__ "whitespaces" =
  [ \t\n\r]*


// Keywords

SELECT   = "SELECT"i
FROM     = "FROM"i
USING    = "USING"i
SCOPE    = "SCOPE"i
WHERE    = "WHERE"i
OR       = "OR"i
AND      = "AND"i
NOT      = "NOT"i
GROUP    = "GROUP"i
BY       = "BY"i
ORDER    = "ORDER"i
ASC      = "ASC"i
DESC     = "DESC"i
NULLS    = "NULLS"i
FIRST    = "FIRST"i
LAST     = "LAST"i
LIMIT    = "LIMIT"i
OFFSET   = "OFFSET"i
TRUE     = "TRUE"i
FALSE    = "FALSE"i
NULL     = "NULL"i
