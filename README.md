# soql-parse

Parse [SOQL] query string to abstract syntax tree in JavaScript.

[![Build Status](https://travis-ci.org/stomita/soql-parse.svg?branch=master)](https://travis-ci.org/stomita/soql-parse)

## Online Demo

https://stomita.github.io/soql-parse/

## Install

```
npm install soql-parse
```

## Usage

```js
import { parse } from 'soql-parse';

const soql = `
  SELECT Id from Account
  WHERE Name LIKE 'A%' and Type IN ('Partner', 'Customer')
  ORDER BY CreatedDate DESC
  LIMIT 10
`;

const parsed = parse(soql);
console.log(parsed);
```

Result:

```json
{
    "type": "Query",
    "fields": [
        {
            "type": "FieldReference",
            "path": [
                "Id"
            ]
        }
    ],
    "object": {
        "type": "ObjectReference",
        "name": "Account"
    },
    "condition": {
        "type": "LogicalCondition",
        "operator": "AND",
        "left": {
            "type": "ComparisonCondition",
            "field": {
                "type": "FieldReference",
                "path": [
                    "Name"
                ]
            },
            "operator": "LIKE",
            "value": {
                "type": "string",
                "value": "A%"
            }
        },
        "right": {
            "type": "ComparisonCondition",
            "field": {
                "type": "FieldReference",
                "path": [
                    "Type"
                ]
            },
            "operator": "IN",
            "value": {
                "type": "list",
                "values": [
                    {
                        "type": "string",
                        "value": "Partner"
                    },
                    {
                        "type": "string",
                        "value": "Customer"
                    }
                ]
            }
        }
    },
    "sort": [
        {
            "field": {
                "type": "FieldReference",
                "path": [
                    "CreatedDate"
                ]
            },
            "direction": "DESC"
        }
    ],
    "limit": {
        "type": "number",
        "value": 10
    }
}
```
