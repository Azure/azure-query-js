###
# 
# Copyright (c) Microsoft Corporation
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


{ JavaScriptToQueryVisitor } = require '../lib/JavaScriptToQueryVisitor'
{ JavaScript } = require '../lib/JavaScript'
JS = require '../lib/JavaScriptNodes'
Q = require '../lib/QueryNodes'
assert = require 'assert'
{ debug } = require 'util'


suite 'JavaScriptToQueryVisitor'

test 'Throws for unknown nodes', ->
    context =
        environment: { }
        source: "fail"
        expression: new JS.EmptyStatement()
    v = new JavaScriptToQueryVisitor context
    assert.throws -> v.visit(context.expression)

test 'Trivial Expressions', ->
    expr = JavaScript.transformConstraint (-> 42), []
    assert.equal expr.type, 'ConstantExpression'
    assert.equal expr.value, 42

    expr = JavaScript.transformConstraint ((a) -> a), [42]
    assert.equal expr.type, 'ConstantExpression'
    assert.equal expr.value, 42

    expr = JavaScript.transformConstraint (-> @ownsCar), []
    assert.equal expr.type, 'MemberExpression'
    assert.equal expr.member, 'ownsCar'

test 'Basic expressions', ->
    expr = JavaScript.transformConstraint (-> @age == 42), []
    assert.equal expr.type, 'BinaryExpression'
    assert.equal expr.operator, Q.BinaryOperators.Equal
    assert.equal expr.left.type, 'MemberExpression'
    assert.equal expr.right.type, 'ConstantExpression'

    expr = JavaScript.transformConstraint (-> @id + 1), []
    assert.equal expr.type, 'BinaryExpression'
    assert.equal expr.operator, Q.BinaryOperators.Add
    assert.equal expr.left.type, 'MemberExpression'
    assert.equal expr.right.type, 'ConstantExpression'

test 'Complex Expressions', ->
    expr = JavaScript.transformConstraint (-> @age == 42 && (@salary / 1000) > 40), []
    assert.equal expr.type, 'BinaryExpression'
    assert.equal expr.operator, Q.BinaryOperators.And
    assert.equal expr.left.operator, Q.BinaryOperators.Equal
    assert.equal expr.right.operator, Q.BinaryOperators.GreaterThan