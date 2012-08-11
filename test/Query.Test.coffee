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

{ Query } = require '../lib/Query'
Q = require '../lib/QueryNodes'
assert = require 'assert'
_ = require '../lib/Utilities'

suite 'Query'

test 'Instantiate', ->
    q = new Query('customers')

    assert.throws -> new Query()
    assert.throws -> new Query(42)

    q = new Query('customers')
    assert.equal q.getComponents().table, 'customers'

    q = new Query('customers', 42)
    assert.equal q.getComponents().context, 42

test 'Set Components', ->
    q = new Query('customers')
    q.setComponents(
        skip: 10
        take: 5
        table: 'users'
        includeTotalCount: true)
    assert.equal q.getComponents().skip, 10
    assert.equal q.getComponents().take, 5
    assert.equal q.getComponents().table, 'users'
    assert.equal q.getComponents().includeTotalCount, true

test 'Expressions are included', ->
    assert.notEqual Query.Expressions, null
    assert.ok new Query.Expressions.ConstantExpression(42)

test 'Query Providers', ->
    Query.registerProvider 'Yoda',
        toQuery: (query) ->
            table = query.getComponents().table
            selections = query.getComponents().selections
            "From #{table} select #{selections} you must."

    q = new Query('customers').select('name', 'age')
    assert.equal q.toYoda(), "From customers select name,age you must."

test 'OrderBy', ->
    q = new Query('customers').orderBy('birthdate')
    assert.equal q.getComponents().ordering.birthdate, true

    q = new Query('customers').orderBy('a', 'b').orderByDescending('c')
    ordering = q.getComponents().ordering
    assert.equal ordering.a, true
    assert.equal ordering.b, true
    assert.equal ordering.c, false

    q = new Query('customers').orderBy()
    assert.ok q.getComponents().ordering

    assert.throws -> new Query('customers').orderBy(42)

test 'OrderByDescending', ->
    q = new Query('customers').orderByDescending('birthdate')
    assert.equal q.getComponents().ordering.birthdate, false

    q = new Query('customers').orderByDescending('a', 'b').orderBy('c')
    ordering = q.getComponents().ordering
    assert.equal ordering.a, false
    assert.equal ordering.b, false
    assert.equal ordering.c, true

    q = new Query('customers').orderByDescending()
    assert.ok q.getComponents().ordering

    assert.throws -> new Query('customers').orderByDescending(42)

test 'Ordering Stomp', ->
    q = new Query('customers').orderBy('birthdate').orderByDescending('birthdate')
    assert.equal q.getComponents().ordering.birthdate, false

test 'Take', ->
    q = new Query('customers')
    assert.equal q.getComponents().take, null

    q = new Query('customers').take(5)
    assert.equal q.getComponents().take, 5

    q = new Query('customers').take(5).take(7)
    assert.equal q.getComponents().take, 7

    assert.throws -> new Query('customers').take('a break')

test 'Skip', ->
    q = new Query('customers')
    assert.equal q.getComponents().skip, null

    q = new Query('customers').skip(5)
    assert.equal q.getComponents().skip, 5

    q = new Query('customers').skip(5).skip(7)
    assert.equal q.getComponents().skip, 7

    assert.throws -> new Query('customers').skip('the line')

test 'Include Total Count', ->
    q = new Query('foo')
    assert.equal q.getComponents().includeTotalCount, false

    q.includeTotalCount()
    assert.equal q.getComponents().includeTotalCount, true

    q.includeTotalCount()
    assert.equal q.getComponents().includeTotalCount, true

test 'Select Simple', ->
    q = new Query('customers')
    assert.equal q.getComponents().selections.length, 0

    q = new Query('customers').select('name')
    assert.equal q.getComponents().selections[0], 'name'
    assert.equal q.getComponents().projection, null

    q = new Query('customers').select('name').select('age')
    assert.equal q.getComponents().selections[0], 'name'
    assert.equal q.getComponents().selections[1], 'age'

    q = new Query('customers').select('name', 'age')
    assert.equal q.getComponents().selections[0], 'name'
    assert.equal q.getComponents().selections[1], 'age'

    assert.throws -> new Query('customers').select(42)

test 'Select function', ->
    q = new Query('customers').select(-> this.first + ' ' + this.last)
    assert.ok(_.isFunction q.getComponents().projection)
    ###
    assert.equal q.getComponents().selections.length, 2
    assert.equal q.getComponents().selections[0], 'first'
    assert.equal q.getComponents().selections[1], 'last'
    ###
    assert.equal q.getComponents().selections.length, 0

test 'Where Simple', ->
    q = new Query('customers')
    assert.equal q.getComponents().filters, null

    assert.throws -> new Query('customers').where(42)

test 'Where Literal', ->
    q = new Query('customers').where('name eq ?', 'Bob')
    assert.ok q.getComponents().filters
    assert.equal q.getComponents().filters.type, 'LiteralExpression'
    assert.equal q.getComponents().filters.queryString, 'name eq ?'
    assert.equal q.getComponents().filters.args[0], 'Bob'

    # Join the two literal clauses via an AND exprssion
    q.where('age gt 20')
    assert.equal q.getComponents().filters.type, 'BinaryExpression'
    assert.equal q.getComponents().filters.operator, Q.BinaryOperators.And
    assert.equal q.getComponents().filters.left.type, 'LiteralExpression'
    assert.equal q.getComponents().filters.right.type, 'LiteralExpression'

    # AND on another literal on the right side
    q.where('age lt 65')
    assert.equal q.getComponents().filters.type, 'BinaryExpression'
    assert.equal q.getComponents().filters.operator, Q.BinaryOperators.And
    assert.equal q.getComponents().filters.left.type, 'BinaryExpression'
    assert.equal q.getComponents().filters.right.type, 'LiteralExpression'

test 'Where Object', ->
    # An empty object does nothing
    q = new Query('customers').where({ })
    assert.equal q.getComponents().filters, null

    # Add a single equality check
    q = new Query('customers').where(name : 'Bob')
    assert.equal q.getComponents().filters.type, 'BinaryExpression'
    assert.equal q.getComponents().filters.operator, Q.BinaryOperators.Equal
    assert.equal q.getComponents().filters.left.type, 'MemberExpression'
    assert.equal q.getComponents().filters.right.type, 'ConstantExpression'

    # An empty object shouldn't modify the existing filter
    q.where({ })
    assert.equal q.getComponents().filters.type, 'BinaryExpression'
    assert.equal q.getComponents().filters.operator, Q.BinaryOperators.Equal
    assert.equal q.getComponents().filters.left.type, 'MemberExpression'
    assert.equal q.getComponents().filters.right.type, 'ConstantExpression'

    # Multiple values should AND together the clauses from left to right
    q = new Query('customers').where(name : 'Bob', age : 12)
    filters = q.getComponents().filters;
    assert.equal filters.type, 'BinaryExpression'
    assert.equal filters.operator, Q.BinaryOperators.And
    assert.equal filters.left.type, 'BinaryExpression'
    assert.equal filters.left.left.type, 'MemberExpression'
    assert.equal filters.left.right.type, 'ConstantExpression'
    assert.equal filters.left.right.value, 'Bob'
    assert.equal filters.right.type, 'BinaryExpression'
    assert.equal filters.right.left.type, 'MemberExpression'
    assert.equal filters.right.right.type, 'ConstantExpression'
    assert.equal filters.right.right.value, 12

test 'Where simple function', ->
    q = new Query('customers').where(-> @name == 'Bob')
    assert.equal q.getComponents().filters.type, 'BinaryExpression'
    assert.equal q.getComponents().filters.operator, Q.BinaryOperators.Equal
    assert.equal q.getComponents().filters.left.type, 'MemberExpression'
    assert.equal q.getComponents().filters.right.type, 'ConstantExpression'

test 'OData Provider hooked up', ->
    q = new Query('customers')
    assert.ok q.toOData

test 'Complete example', ->
    minAge = 18
    q = new Query('customers')
        .where(name : 'Bob')
        .where(((min) -> @age >= min), minAge)
        .select('name', 'age')
        .orderBy('age')
        .orderByDescending('name')
        .take(10);
    odata = q.toOData()
    assert.equal odata, "/customers?$filter=((name eq 'Bob') and (age ge 18))&$orderby=age,name desc&$top=10&$select=name,age"

test 'Versioning', ->
    q = new Query('test')
    assert.equal q.getComponents().version, 0
    q.where({age: 12})
    assert.equal q.getComponents().version, 1
    assert.equal q.getComponents().version, 1
    q.select('age')
    assert.equal q.getComponents().version, 2
    q.orderBy('age')
    assert.equal q.getComponents().version, 3
    q.orderByDescending('age')
    assert.equal q.getComponents().version, 4
    q.skip(2)
    assert.equal q.getComponents().version, 5
    q.take(3)
    assert.equal q.getComponents().version, 6
    q.includeTotalCount()
    assert.equal q.getComponents().version, 7
    q.setComponents(null)
    assert.equal q.getComponents().version, 8
