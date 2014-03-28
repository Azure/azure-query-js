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

{ PartialEvaluator, IndependenceNominator } = require '../lib/PartialEvaluator'
{ JavaScript } = require '../lib/JavaScript'
JS = require '../lib/JavaScriptNodes'
assert = require 'assert'
{ debug } = require 'util'


suite 'PartialEvaluator'

test 'Simple Independence', ->
    assertIndependence = (expectIndependent, expression) ->
        nominator = new IndependenceNominator expression: expression
        nominator.visit expression
        assert.equal expectIndependent, expression.__independent

    assertIndependence true, new JS.Literal 'text'
    assertIndependence true, new JS.Literal 42
    assertIndependence true, new JS.Identifier 'count'
    assertIndependence false, new JS.ThisExpression
    assertIndependence false, new JS.MemberExpression(
        new JS.ThisExpression,
        new JS.Identifier '_id')

test 'Complex Independence', ->
    assertIndependence = (expectIndependent, func, env) ->
        context = JavaScript.getExpression func, env ? []
        nominator = new IndependenceNominator context
        nominator.visit context.expression
        if expectIndependent != context.expression.__independent
            debug JSON.stringify(context.expression, null, '    ')
        assert.equal expectIndependent, context.expression.__independent

    assertIndependence true, (-> 1 + 1), []
    assertIndependence true, (-> 1 + count), []
    assertIndependence true, ((a) -> a), [1]
    assertIndependence false, (-> @age == 21), []
    assertIndependence false, (-> 1 + @_id), []

simplify = (func, env) ->
    context = JavaScript.getExpression func, env ? []
    PartialEvaluator.evaluate context

test 'Simple Partial Evaluation', ->    
    expr = simplify (-> 42), []
    assert.equal expr.type, 'Literal'
    assert.equal expr.value, 42

    expr = simplify ((a) -> a), [42]
    assert.equal expr.type, 'Literal'
    assert.equal expr.value, 42

    expr = simplify ((a) -> 2 + a), [2]
    assert.equal expr.type, 'Literal'
    assert.equal expr.value, 4

    expr = simplify (-> @count), []
    assert.equal expr.type, 'MemberExpression'
    assert.equal expr.property.name, 'count'

test 'Complex partial evaluation', ->
    expr = simplify (-> @month == new Date(1983, 10, 21).getMonth() + 1), []
    assert.equal expr.type, 'BinaryExpression'
    assert.equal expr.operator, '==='
    assert.equal expr.left.type, 'MemberExpression'
    assert.equal expr.left.property.name, 'month'
    assert.equal expr.right.type, 'Literal'
    assert.equal expr.right.value, 11
