# soql-parse

Parse [SOQL](https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql.htm) query string to abstract syntax tree in JavaScript.

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
Select Id, Name, toLabel(Type) from Account
WHERE Name like 'A%' and Type IN ('Partner', 'Customer')
ORDER by CreatedDate DESC
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
        },
        {
            "type": "FieldReference",
            "path": [
                "Name"
            ]
        },
        {
            "type": "FunctionCall",
            "name": "toLabel",
            "arguments": [
                {
                    "type": "FieldReference",
                    "path": [
                        "Type"
                    ]
                }
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
