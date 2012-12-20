###
#
# Copyright 2011 Microsoft Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
###

{ JavaScript } = require '../lib/JavaScript'
assert = require 'assert'
{ debug } = require 'util'

suite 'JavaScript'

test 'getExpression expression', ->
    context = JavaScript.getExpression (() -> 1), []
    assert.equal context.expression.type, 'Literal'
    assert.equal context.expression.value, 1

    assert.throws (-> JavaScript.getExpression ((a) -> 1 + 1; a), [1]),
        ((ex) -> ex.indexOf('single return statement') > 0)
    assert.throws -> JavaScript.getExpression 'not!code+*@44 4 4', []

test 'getExpression source', ->
    context = JavaScript.getExpression ((a) -> 2 + a), [1]
    source = context.source[context.expression.range[0]..(context.expression.range[1] - 1)]
    assert.equal source, '2 + a'

    context = JavaScript.getExpression ((a) -> monkey * a), [1]
    source = context.source[context.expression.range[0]..context.expression.range[1]]
    assert.ok source.indexOf('monkey') >= 0

test 'getExpression environment', ->
    context = JavaScript.getExpression ((a) -> 2 + a), [1]
    assert.equal context.environment.a, 1

    context = JavaScript.getExpression ((a, b) -> a == b), [1, 'x']
    assert.equal context.environment.a, 1
    assert.equal context.environment.b, 'x'

    assert.throws (-> JavaScript.getExpression ((abc) -> abc + 1), []),
        ((ex) -> ex.toString().indexOf('abc') >= 0)
    assert.throws (-> JavaScript.getExpression ((a) -> a + 1), [1, 42]),
        ((ex) -> ex.toString().indexOf('42') >= 0)

