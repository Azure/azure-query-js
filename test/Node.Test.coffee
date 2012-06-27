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

{ Node, Visitor } = require '../lib/Node.js'
assert = require 'assert'
{ print } = require 'util'



suite 'Node'

test 'Instantiate', ->
    n = new Node

test 'Default Tag', ->
    n = new Node
    assert.equal n.type, 'Node'

test 'Derived Tag', ->
    class Expression extends Node
        constructor: ->
            super()
    n = new Expression
    assert.equal n.type, 'Expression'

test 'Derived Tag no super()', ->
    class Expression extends Node
        constructor: ->
    n = new Expression
    assert.equal n.type, 'Node'

test 'Derived Tag in Hierarchy', ->
    class Expression extends Node
        constructor: ->
            super()
    class BinaryExpression extends Node
        constructor: ->
            super()
    n = new BinaryExpression
    assert.equal n.type, 'BinaryExpression'




suite 'Visitor'

test 'Instantiate a visitor', ->
    new Visitor()

test 'Visit null', ->
    v = new Visitor()
    assert.equal v.visit(null), null

test 'Visit no type', ->
    v = new Visitor()
    assert.equal v.visit(42), 42

test 'Visit no handler throws', ->
    v = new Visitor()
    assert.throws -> v.visit(type: 'Boom')

test 'Visit looks up type', ->
    v = new Visitor()
    v.Int = (node) -> 42
    assert.equal v.visit(type: 'Int', value: 12), 42
