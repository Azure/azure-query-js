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

_ = require './Utilities'

###
# The base Node class for all expressions used for analysis and translation by
# visitors.  It's designed to interop with other modules that create expression
# trees using object literals with a type tag.
###
exports.Node = class Node
    ###
    # Type tag of the node that allows for eash dispatch in visitors.  This is
    # automatically set in the constructor (so it's important to call super() in
    # derived Node classes).
    ###
    type: 'Node'

    ###
    # Initializes a new instance of the Node class and sets its type tag.
    ###
    constructor: ->
        @type = _.functionName @constructor


###
# Base class for all visitors
###
exports.Visitor =
    class Visitor

        constructor: ->

        ###
        # Visit a node.
        ###
        visit: (node) ->
            if _.isArray node
                @visit(element) for element in node
            else if not node?.type
                node
            else if not _.isFunction(@[node.type])
                throw "Unsupported expression #{@getSource(node)}"
            else
                @[node.type](node)

        ###
        # Get the source code corresponding to a node.
        ###
        getSource: (node) ->
            ### It is expected this will be overridden in derived visitors. ###
            null
