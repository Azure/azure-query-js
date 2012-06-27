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

js = require '../lib/JavaScriptNodes'
assert = require 'assert'
_ = require '../lib/Utilities'
{ print } = require 'util'

suite 'JavaScriptNodes'

test 'Instantiate a node', ->
    n = new js.Literal(42)
    assert.equal(n.value, 42)

test 'All nodes call super', ->
    for name, ctor of js when _.isFunction(ctor) && name != 'JavaScriptVisitor'
        instance = new ctor()
        assert.equal(instance.type, name)

test 'All nodes are visited', ->
    visitor = new js.JavaScriptVisitor()
    for name, ctor of js when _.isFunction(ctor) && name != 'JavaScriptVisitor'
        assert.ok(_.isFunction(visitor[name]))
