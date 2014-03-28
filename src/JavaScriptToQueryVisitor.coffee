###
# ----------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# ----------------------------------------------------------------------------
###

_ = require './Utilities'
JS = require './JavaScriptNodes'
Q = require './QueryNodes'

###
# Walk the JavaScriptExpression tree and convert its nodes into QueryExpression
# trees
###
exports.JavaScriptToQueryVisitor =
    class JavaScriptToQueryVisitor extends JS.JavaScriptVisitor
        constructor: (@context) ->

        ### Get the source code for a given node ###
        getSource: (node) ->
            @context.source[node?.range?[0]..(node?.range?[1] - 1)]
        
        ### Throw an exception for an invalid node. ###
        invalid: (node) ->
            throw "The expression '#{@getSource node}'' is not supported."

        ### Unary expressions just map operators ###
        translateUnary: (node, mapping) ->
            op = mapping[node.operator]        
            if op
                value = @visit(node.argument)
                new Q.UnaryExpression op, value
            else
                null

        ### Binary expressions just map operators ###
        translateBinary: (node, mapping) ->
            op = mapping[node.operator]
            if (op)
                left = @visit(node.left)
                right = @visit(node.right)
                new Q.BinaryExpression op, left, right
            else
                null

        ###
        # The base visit method will throw exceptions for any nodes that remain
        # untransformed (which allows us to only bother defining meaningful
        # translations)
        ###
        visit: (node) ->
            visited = super node
            if node == visited
                @invalid node
            visited

        MemberExpression: (node) ->
            expr =
                if node?.object?.type == 'ThisExpression' && node?.property?.type == 'Identifier'
                    ### Simple member access ###
                    new Q.MemberExpression node.property.name
                else if node?.object?.type == 'MemberExpression' && node.object.object?.type == 'ThisExpression' && node.property.type == 'Identifier'
                    ### Methods that look like properties ###
                    if node.property.name == 'length'
                        new Q.InvocationExpression Q.Methods.Length, (new Q.MemberExpression node.object.property.name)
            expr ? (super node)

        Literal: (node) ->
            new Q.ConstantExpression node.value

        UnaryExpression: (node) ->
            if node.operator == '+'
                ### Ignore the + in '+52' ###
                @visit(node.argument)
            else
                mapping = 
                    '!': Q.UnaryOperators.Not
                    '-': Q.UnaryOperators.Negate
                (@translateUnary node, mapping) ? (super node)

        UpdateExpression: (node) ->
            mapping =
                '++': Q.UnaryOperators.Increment
                '--': Q.UnaryOperators.Decrement
            (@translateUnary node, mapping) ? (super node)

        LogicalExpression: (node) ->
            mapping =
                '&&': Q.BinaryOperators.And
                '||': Q.BinaryOperators.Or
            (@translateBinary node, mapping) ? (super node)

        BinaryExpression: (node) ->
            mapping =
                '+': Q.BinaryOperators.Add
                '-': Q.BinaryOperators.Subtract
                '*': Q.BinaryOperators.Multiply
                '/': Q.BinaryOperators.Divide
                '%': Q.BinaryOperators.Modulo
                '>': Q.BinaryOperators.GreaterThan
                '>=': Q.BinaryOperators.GreaterThanOrEqual
                '<': Q.BinaryOperators.LessThan
                '<=': Q.BinaryOperators.LessThanOrEqual
                '!=': Q.BinaryOperators.NotEqual
                '!==': Q.BinaryOperators.NotEqual
                '==': Q.BinaryOperators.Equal
                '===': Q.BinaryOperators.Equal
            (@translateBinary node, mapping) ?
                if node.operator == 'in' && node.right?.type == 'Literal' && _.isArray(node.right?.value)
                    ###
                    # Transform the 'varName in [x, y, z]' operator into a series of
                    # comparisons like varName == x || varName == y || varName == z.
                    ###
                    if node.right.value.length > 0
                        left = @visit(node.left)
                        Q.QueryExpression.groupClauses Q.BinaryOperators.Or,
                            for value in node.right.value
                                ###
                                # If we've got an array of objects who each have
                                # a single property, we'll use the value of that
                                # property.  Otherwise we'll throw an exception.
                                ###
                                if _.isObject value
                                    properties = (v for k, v of value)
                                    if properties?.length != 1
                                        throw "in operator requires comparison objects with a single field, not #{value} (#{JSON.stringify value}), for expression '#{@getSource node}'"
                                    value = properties[0]
                                new Q.BinaryExpression(
                                    Q.BinaryOperators.Equal,
                                    left,
                                    new Q.ConstantExpression(value))
                    else
                        ###
                        # If the array of values is empty, change the query to
                        # true == false since it can't be satisfied.
                        ###
                        new Q.BinaryExpression(
                            Q.BinaryOperators.Equal,
                            new Q.ConstantExpression(true),
                            new Q.ConstantExpression(false))
                else
                    super node

        CallExpression: (node) ->
            getSingleArg = (name) =>
                if node.arguments?.length != 1
                    throw "Function #{name} expects one argument in expression '#{@getSource node}'"
                @visit(node.arguments[0])
            getTwoArgs = (member, name) =>
                if node.arguments?.length != 2
                    throw "Function #{name} expects two arguments in expression '#{@getSource node}'"
                [member, @visit(node.arguments[0]), @visit(node.arguments[1])]

            ###
            # Translate known method calls that aren't attached to an instance.
            # Note that we can compare against the actual method because the
            # partial evaluator will have converted it into a literal for us.
            ###
            func = node?.callee?.value
            expr = 
                if func == Math.floor
                    new Q.InvocationExpression Q.Methods.Floor, [getSingleArg 'floor']
                else if func == Math.ceil
                    new Q.InvocationExpression Q.Methods.Ceiling, [getSingleArg 'ceil']
                else if func == Math.round
                    new Q.InvocationExpression Q.Methods.Round, [getSingleArg 'round']
                else
                    ###
                    # Translate methods dangling off an instance
                    ###
                    if node.callee.type == 'MemberExpression' && node.callee.object?.__hasThisExp == true
                        if node?.callee?.object?.type == 'CallExpression'
                            member = @visit(node.callee.object)
                        else
                            member = new Q.MemberExpression node.callee.object?.property?.name

                        method = node.callee?.property?.name
                        if method == 'toUpperCase'
                            new Q.InvocationExpression Q.Methods.ToUpperCase, [member]
                        else if method == 'toLowerCase'
                            new Q.InvocationExpression Q.Methods.ToLowerCase, [member]
                        else if method == 'trim'
                            new Q.InvocationExpression Q.Methods.Trim, [member]
                        else if method == 'indexOf'
                            new Q.InvocationExpression Q.Methods.IndexOf, [member, getSingleArg 'indexOf']
                        else if method == 'concat'
                            new Q.InvocationExpression Q.Methods.Concat, [member, getSingleArg 'concat']
                        else if method == 'substring' || method == 'substr'
                            new Q.InvocationExpression Q.Methods.Substring, (getTwoArgs member, 'substring')
                        else if method == 'replace'
                            new Q.InvocationExpression Q.Methods.Replace, (getTwoArgs member, 'replace')
                        else if method == 'getFullYear' || method == 'getUTCFullYear'
                            new Q.InvocationExpression Q.Methods.Year, [member]
                        else if method == 'getYear'
                            new Q.BinaryExpression(
                                Q.BinaryOperators.Subtract,
                                new Q.InvocationExpression(Q.Methods.Year, [member]),
                                new Q.ConstantExpression(1900))
                        else if method == 'getMonth' || method == 'getUTCMonth'
                            ### getMonth is 0 indexed in JavaScript ###
                            new Q.BinaryExpression(
                                Q.BinaryOperators.Subtract, 
                                new Q.InvocationExpression(Q.Methods.Month, [member]),
                                new Q.ConstantExpression(1))
                        else if method == 'getDate' || method == 'getUTCDate'
                            new Q.InvocationExpression Q.Methods.Day, [member]                        
                        
                        
            expr ? (super node)
