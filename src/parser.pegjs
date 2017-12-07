{
  function assign() {
    return Object.assign.apply(null, arguments);
  }

  function createLogicalConditionTree(operator, head, tail) {
    var result = head;
    for (var i = 0; i < tail.length; i++) {
      result = {
        type: 'LogicalCondition',
        operator: operator,
        left: result,
        right: tail[i],
      };
    }
    return result;
  }
}


Query =
  _ SELECT
  __ fields:QueryFieldList
  __ object:FromClause
  scope:(__ ScopeClause)?
  condition:(__ WhereClause)?
  group:(__ GroupByClause)?
  sort:(__ OrderByClause)?
  limit:(__ LimitClause)?
  offset:(__ OffsetClause)?
  selectFor:(__ SelectForClause)?
  _ {
    return assign(
      {
        type: 'Query',
        fields: fields,
        object: object,
      },
      scope ? { scope: scope[1] } : {},
      condition ? { condition: condition[1] } : {},
      group ? { group: group[1] } : {},
      sort ? { sort: sort[1] } : {},
      limit ? { limit: limit[1] } : {},
      offset ? { offset: offset[1] } : {},
      selectFor ? { selectFor: selectFor[1] } : {}
    );
  }

QueryFieldList =
  head:QueryFieldListItem _ COMMA _ tail:QueryFieldList {
    return [head].concat(tail);
  }
/ field:QueryFieldListItem {
    return [field]
  }

QueryFieldListItem =
  SubQuery
/ QueryField

QueryField =
  field:FieldExpr alias:(__ name:Identifier & { return !/^FROM$/i.test(name); })? {
    return (
      alias ?
      assign({}, field, { alias: alias[0] }) :
      field
    );
  }

FieldExpr =
  FunctionCall
/ FieldReference

FunctionCall =
  func:Identifier _ LPAREN _ args:FunctionArg* _ RPAREN {
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
  head:Identifier _ DOT _ tail:FieldPath {
    return [head].concat(tail);
  }
/ field:Identifier {
    return [field];
  }

FromClause =
  FROM __ object:Identifier {
    return object;
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

Condition =
  OrCondition

OrCondition =
  head:AndCondition tail:(__ OR __ condition:AndCondition { return condition; })* {
    return createLogicalConditionTree('OR', head, tail);
  }

AndCondition =
  head:NotCondition tail:(__ AND __ condition:NotCondition { return condition; })* {
    return createLogicalConditionTree('AND', head, tail);
  }

NotCondition =
  NOT __ condition:ParenCondition {
    return {
      type: 'NegateCondition',
      operator: 'NOT',
      condition: condition,
    };
  }
/ ParenCondition

ParenCondition =
  LPAREN _ condition:Condition _ RPAREN {
    return assign({}, condition, { parentheses: true });
  }
/ ComparisonCondition

ComparisonCondition =
  field:FieldExpr
  operator:(
      _ o:SpecialCharComparisonOperator _ { return o; }
    / __ o:ComparisonOperator __ { return o; }
  )
  value:ComparisonValue {
    return {
      type: 'ComparisonCondition',
      field: field,
      operator: operator,
      value: value,
    };
  }

SpecialCharComparisonOperator =
  "=" / "!=" / "<" / "<=" / ">" / ">="

ComparisonOperator =
  "LIKE"i { return 'LIKE'; }
/ "IN"i { return 'IN'; }
/ "NOT"i __ "IN"i { return 'NOT IN'; }
/ "INCLUDES"i { return 'INCLUDES'; }
/ "EXCLUDES"i { return 'EXCLUDES'; }

ComparisonValue =
  SubQuery
/ Literal
/ BindVariable

GroupByClause =
  GROUP __ BY __ ROLLUP _ LPAREN _ fields:GroupItemList _ RPAREN {
    return {
      type: 'RollupGrouping',
      fields: fields
    };
  }
/ GROUP __ BY __ CUBE _ LPAREN _ fields:GroupItemList _ RPAREN {
    return {
      type: 'CubeGrouping',
      fields: fields
    };
  }
/ GROUP __ BY __ items:GroupItemList {
    return items;
  }

GroupItemList =
  head:GroupItem _ COMMA _ tail:GroupItemList {
    return [head].concat(tail);
  }
/ group:GroupItem {
    return [group];
  }

GroupItem =
  FieldExpr

OrderByClause =
  ORDER __ BY __ sort:SortItemList {
    return sort;
  }

SortItemList =
  head:SortItem _ COMMA _ tail:SortItemList {
    return [head].concat(tail);
  }
/ sort:SortItem {
    return [sort];
  }

SortItem =
  field:FieldExpr
  direction:(__ SortDir)?
  nullOrder:(__ NullOrder)? {
    return {
      field: field,
      direction: direction && direction[1],
      nullOrder: nullOrder && nullOrder[1],
    };
  }

SortDir =
  ASC { return 'ASC'; }
/ DESC { return 'DESC'; }

NullOrder =
  NULLS __ FIRST { return 'FIRST'; }
/ NULLS __ LAST { return 'LAST'; }

LimitClause =
  LIMIT __ n:Int {
    return parseInt(n, 10);
  }

OffsetClause =
  OFFSET __ n:Int {
    return parseInt(n, 10);
  }

SelectForClause =
  FOR __ VIEW { return 'VIEW'; }
/ FOR __ REFERENCE { return 'REFERENCE'; }

SubQuery =
  LPAREN
  _ SELECT
  __ fields:SubQueryFieldList
  __ object:FromClause
  condition:(__ WhereClause)?
  sort:(__ OrderByClause)?
  limit:(__ LimitClause)?
  _ RPAREN {
    return assign(
      {
        type: 'Query',
        fields: fields,
        object: object,
      },
      condition ? { condition: condition[1] } : {},
      sort ? { sort: sort[1] } : {},
      limit ? { limit: limit[1] } : {}
    );
  }

SubQueryFieldList =
  head:SubQueryFieldListItem _ COMMA _ tail:SubQueryFieldList {
    return [head].concat(tail);
  }
/ field:SubQueryFieldListItem {
    return [field]
  }

SubQueryFieldListItem = FieldExpr

BindVariable =
  COLON identifier:Identifier {
    return {
      type: 'BindVariable',
      identifier: identifier,
    };
  }

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
  int_:Int frac:Frac         { return parseFloat(int_ + frac); }
/ int_:Int                   { return parseFloat(int_); }

Int
  = digit19:Digit19 digits:Digits { return digit19 + digits; }
  / digit:Digit
  / op:[+-] digits:Digits { return op + digit19 + digits; }
  / op:[+-] digit:Digit { return op + digit; }

Frac
  = "." digits:Digits { return "." + digits; }

Digits
  = digits:Digit+ { return digits.join(""); }

Digit   = [0-9]
Digit19 = [1-9]

HexDigit
  = [0-9a-fA-F]

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
COLON  = ":"

_ "spacer" =
  [ \t\n\r]*

__ "whitespaces" =
  [ \t\n\r]+


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
ROLLUP   = "ROLLUP"i
CUBE     = "CUBE"i
ORDER    = "ORDER"i
ASC      = "ASC"i
DESC     = "DESC"i
NULLS    = "NULLS"i
FIRST    = "FIRST"i
LAST     = "LAST"i
LIMIT    = "LIMIT"i
OFFSET   = "OFFSET"i
FOR      = "FOR"i
VIEW     = "VIEW"i
REFERENCE = "REFERENCE"i
TRUE     = "TRUE"i
FALSE    = "FALSE"i
NULL     = "NULL"i
