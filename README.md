# soql-parse

Parse [SOQL] query string to abstract syntax tree.

## Install

```
npm install soql-parse
```

## Usage

```js
import { parse } from 'soql-parse';

const soql = 'SELECT Id FROM Account';

const parsed = parse(soql);

// { type; 'Query', fields: [...], object: { } }
```
