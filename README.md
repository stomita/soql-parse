# soql-parse

Parse [SOQL] query string to abstract syntax tree.

[![Build Status](https://travis-ci.org/stomita/soql-parse.svg?branch=master)](https://travis-ci.org/stomita/soql-parse)

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

## Online Demo

https://stomita.github.io/soql-parse/
