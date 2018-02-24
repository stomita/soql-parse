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

  function isReserved(word) {
    return /^(SELECT|FROM|AS|USING|WHERE|AND|OR|NOT|GROUP|BY|ORDER|LIMIT|OFFSET|FOR|TRUE|FALSE|NULL)$/i.test(word);
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
  field:FieldExpr alias:(__ Identifier)? {
    return (
      alias ?
      assign({}, field, { alias: alias[1] }) :
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
  FROM __
  object:ObjectReference
  aliasObjects:(_ COMMA _ AliasObjectList)? {
    return (
      aliasObjects ?
      assign({}, object, { aliasObjects: aliasObjects[3] }) :
      object
    );
  }

ObjectReference =
  name:Identifier alias:(__ (AS __)? Identifier)? {
    return assign(
      {
        type: 'ObjectReference',
        name: name,
      },
      alias ? { alias: alias[2] } : {}
    );
  }

AliasObjectList =
  head:AliasObjectReference _ COMMA _ tail:AliasObjectList {
    return [head].concat(tail || []);
  }
/ head:AliasObjectReference {
    return [head];
  }

AliasObjectReference =
  path:FieldPath alias:(__ (AS __)? Identifier)? {
    return assign(
      {
        type: 'AliasObjectReference',
        path: path
      },
      alias ? { alias: alias[2] } : {}
    );
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
  "=" / "!=" / "<=" / ">=" / "<" / ">"

ComparisonOperator =
  "LIKE"i { return 'LIKE'; }
/ "IN"i { return 'IN'; }
/ "NOT"i __ "IN"i { return 'NOT IN'; }
/ "INCLUDES"i { return 'INCLUDES'; }
/ "EXCLUDES"i { return 'EXCLUDES'; }

ComparisonValue =
  SubQuery
/ ListLiteral
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
/ GROUP __ BY __ fields:GroupItemList {
    return {
      type: 'Grouping',
      fields: fields,
    };
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
    return assign(
      { field: field },
      direction ? { direction: direction[1] } : {},
      nullOrder ? { nullOrder: nullOrder[1] } : {}
    );
  }

SortDir =
  ASC { return 'ASC'; }
/ DESC { return 'DESC'; }

NullOrder =
  NULLS __ FIRST { return 'FIRST'; }
/ NULLS __ LAST { return 'LAST'; }

LimitClause =
  LIMIT __ value:LimitValue {
    return value;
  }

LimitValue =
  NumberLiteral
/ BindVariable

OffsetClause =
  OFFSET __ value:OffsetValue {
    return value;
  }

OffsetValue =
  NumberLiteral
/ BindVariable

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

Identifier =
  id:([a-zA-Z][0-9a-zA-Z_]* { return text() }) & { return !isReserved(id) } { return id; }

BindVariable =
  COLON identifier:Identifier {
    return {
      type: 'BindVariable',
      identifier: identifier,
    };
  }

ListLiteral =
  LPAREN _ values:LiteralList _ RPAREN {
    return {
      type: 'list',
      values: values,
    };
  }

LiteralList =
  head:Literal _ COMMA _ tail:LiteralList {
    return [head].concat(tail);
  }
/ Literal

Literal =
  StringLiteral
/ ISODateLiteral
/ DateLiteral
/ NumberLiteral
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

Integer2
  = $(Digit Digit)

Integer4
  = $(Digit Digit Digit Digit)

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

ISODate
 = Integer4 "-" Integer2 "-" Integer2

ISOTZ
    = "Z"
    / $(("+" / "-") Integer2 ":" Integer2 )
    / $(("+" / "-") Integer4 )

DateFormatLiteral =
  Integer4 "-" Integer2 "-" Integer2 {
    return {
      type: 'date',
      value: text()
    };
  }

ISOTime
    = $(Integer2 ":" Integer2 ":" Integer2)

ISODateLiteral
    = d:ISODate t:$("T" ISOTime)? z:$ISOTZ? {
        return {
          type: t || z ? 'datetime' : 'date',
          value: text()
        }
    }

DateLiteral =
  d:TODAY {
    return {
      type: 'dateLiteral',
      value: text()
    }
  }
/ d:YESTERDAY {
    return {
      type: 'dateLiteral',
      value: text()
    }
}
/ d:TOMORROW {
    return {
      type: 'dateLiteral',
      value: text()
    }
}
/ d:LAST_WEEK {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:THIS_WEEK {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:NEXT_WEEK {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:LAST_MONTH {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:THIS_MONTH {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:NEXT_MONTH {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:LAST_90_DAYS {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:NEXT_90_DAYS {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:THIS_QUARTER {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:LAST_QUARTER {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:NEXT_QUARTER {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:THIS_YEAR {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:LAST_YEAR {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:NEXT_YEAR {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:THIS_FISCAL_QUARTER {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:LAST_FISCAL_QUARTER {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:NEXT_FISCAL_QUARTER {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:THIS_FISCAL_YEAR {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:LAST_FISCAL_YEAR {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:NEXT_FISCAL_YEAR {
  return {
    type: 'dateLiteral',
    value: text()
  }
}
/ d:LAST_N_DAYS n:$(Digit+) {
  return {
    type: 'dateLiteral',
    value: text(),
    variable: n
  }
}
/ d:NEXT_N_DAYS n:$(Digit+) {
  return {
    type: 'dateLiteral',
    value: text(),
    variable: n
  }
}
/ d:NEXT_N_WEEKS n:$(Digit+) {
  return {
    type: 'dateLiteral',
    value: text(),
    variable: n
  }
}
/ d:LAST_N_WEEKS n:$(Digit+) {
  return {
    type: 'dateLiteral',
    value: text(),
    variable: n
  }
}
/ d:NEXT_N_MONTHS n:$(Digit+) {
  return {
    type: 'dateLiteral',
    value: text(),
    variable: n
  }
}
/ d:LAST_N_MONTHS n:$(Digit+) {
  return {
    type: 'dateLiteral',
    value: text(),
    variable: n
  }
}
/ d:NEXT_N_QUARTERS n:$(Digit+) {
  return {
    type: 'dateLiteral',
    value: text(),
    variable: n
  }
}
/ d:LAST_N_QUARTERS n:$(Digit+) {
  return {
    type: 'dateLiteral',
    value: text(),
    variable: n
  }
}
/ d:NEXT_N_YEARS n:$(Digit+) {
  return {
    type: 'dateLiteral',
    value: text(),
    variable: n
  }
}
/ d:LAST_N_YEARS n:$(Digit+) {
  return {
    type: 'dateLiteral',
    value: text(),
    variable: n
  }
}
/ d:NEXT_N_FISCAL_QUARTERS n:$(Digit+) {
  return {
    type: 'dateLiteral',
    value: text(),
    variable: n
  }
}
/ d:LAST_N_FISCAL_QUARTERS n:$(Digit+) {
  return {
    type: 'dateLiteral',
    value: text(),
    variable: n
  }
}
/ d:NEXT_N_FISCAL_YEARS n:$(Digit+) {
  return {
    type: 'dateLiteral',
    value: text(),
    variable: n
  }
}
/ d:LAST_N_FISCAL_YEARS n:$(Digit+) {
  return {
    type: 'dateLiteral',
    value: text(),
    variable: n
  }
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
AS       = "AS"i
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

// Date Literals

YESTERDAY = "YESTERDAY"i
TODAY = "TODAY"i
TOMORROW = "TOMORROW"i
LAST_WEEK = "LAST_WEEK"i
THIS_WEEK = "THIS_WEEK"i
NEXT_WEEK = "NEXT_WEEK"i
LAST_MONTH = "LAST_MONTH"i
THIS_MONTH = "THIS_MONTH"i
NEXT_MONTH = "NEXT_MONTH"i
LAST_90_DAYS = "LAST_90_DAYS"i
NEXT_90_DAYS = "NEXT_90_DAYS"i
THIS_QUARTER = "THIS_QUARTER"i
LAST_QUARTER = "LAST_QUARTER"i
NEXT_QUARTER = "NEXT_QUARTER"i
THIS_YEAR = "THIS_YEAR"i
LAST_YEAR = "LAST_YEAR"i
NEXT_YEAR = "NEXT_YEAR"i
THIS_FISCAL_QUARTER = "THIS_FISCAL_QUARTER"i
LAST_FISCAL_QUARTER = "LAST_FISCAL_QUARTER"i
NEXT_FISCAL_QUARTER = "NEXT_FISCAL_QUARTER"i
THIS_FISCAL_YEAR = "THIS_FISCAL_YEAR"i
LAST_FISCAL_YEAR = "LAST_FISCAL_YEAR"i
NEXT_FISCAL_YEAR = "NEXT_FISCAL_YEAR"i
LAST_N_DAYS = "LAST_N_DAYS:"i
NEXT_N_DAYS = "NEXT_N_DAYS:"i
NEXT_N_WEEKS = "NEXT_N_WEEKS:"i
LAST_N_WEEKS = "LAST_N_WEEKS:"i
NEXT_N_MONTHS = "NEXT_N_MONTHS:"i
LAST_N_MONTHS = "LAST_N_MONTHS:"i
NEXT_N_QUARTERS = "NEXT_N_QUARTERS:"i
LAST_N_QUARTERS = "LAST_N_QUARTERS:"i
NEXT_N_YEARS = "NEXT_N_YEARS:"i
LAST_N_YEARS = "LAST_N_YEARS:"i
NEXT_N_FISCAL_QUARTERS = "NEXT_N_FISCAL_QUARTERS:"i
LAST_N_FISCAL_QUARTERS = "LAST_N_FISCAL_QUARTERS:"i
NEXT_N_FISCAL_YEARS = "NEXT_N_FISCAL_YEARS:"i
LAST_N_FISCAL_YEARS = "LAST_N_FISCAL_YEARS:"i