import parser from './parser';

/**
 *
 */
export function parse(str, options = {}) {
  const ast = parser.parse(str);
  return ast;
}

export default parse;
