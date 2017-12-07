'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.parse = parse;

var _parser = require('./parser');

var _parser2 = _interopRequireDefault(_parser);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 *
 */
function parse(str) {
  var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};

  var ast = _parser2.default.parse(str);
  return ast;
}

exports.default = parse;