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

q = require '../lib/QueryNodes'
assert = require 'assert'
_ = require '../lib/Utilities'
{ print } = require 'util'

suite 'QueryNodes'

test 'Instantiate a node', ->
    n = new q.ConstantExpression(42)
    assert.equal(n.value, 42)

test 'All nodes call super', ->
    for name, ctor of q when _.isFunction(ctor) && name != 'QueryExpressionVisitor'
        instance = new ctor()
        assert.equal(instance.type, name)

test 'All nodes are visited', ->
    visitor = new q.QueryExpressionVisitor()
    for name, ctor of q when _.isFunction(ctor) && name != 'QueryExpressionVisitor'
        assert.ok(_.isFunction(visitor[name]))

