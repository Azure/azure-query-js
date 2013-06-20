###
# ----------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# ----------------------------------------------------------------------------
###

_ = require './Utilities'
JS = require './JavaScriptNodes'

###
# Partially evaluate a complex expression in the context of its environment.
# This allows us to support arbitrary JavaScript expressions even though we
# only explicitly transform a subset of expressions into QueryExpressions.
#
# For example, assuming we have an expression like (x) -> @id == x + 1 with an
# environment where x == 12, then the entire right hand side of the comparison
# is independent of any values computed by the query and could be replaced with
# the literal value 13.
###
exports.PartialEvaluator = 
    class PartialEvaluator extends JS.JavaScriptVisitor
        constructor: (@context) ->

        visit: (node) ->
            if not node.__independent || node.type == 'Literal' || (not node.type)
                ###
                # If the node isn't independent or it's already a literal, then
                # just keep walking the tree
                ###
                super node
            else
                ###
                # Otherwse we'll evaluate the node in the context of the
                # environment by either looking up identifiers directly or
                # evaluating whole sub expressions
                ###
                if node.type == 'Identifier' && @context.environment[node.name]
                    new JS.Literal @context.environment[node.name]
                else
                    ###
                    # Evaluate the source of the sub expression in the context
                    # of the environment
                    ###
                    source = @context.source[node?.range?[0]..(node?.range?[1] - 1)]
                    params = (key for key, value of @context.environment) ? []
                    values = ((JSON.stringify value) for key, value of @context.environment) ? []
                    thunk = "(function(#{params}) { return #{source}; })(#{values})"
                    value = eval thunk
                    new JS.Literal value
          
        @evaluate: (context) ->
            nominator = new IndependenceNominator context
            nominator.visit(context.expression)

            evaluator = new PartialEvaluator context
            evaluator.visit(context.expression)

###
# Nominate independent nodes in an expression tree that don't depend on any
# server side values.
###
exports.IndependenceNominator =
    class IndependenceNominator extends JS.JavaScriptVisitor
        constructor: (@context) ->

        Literal: (node) ->
            super node
            node.__independent = true
            node.__hasThisExp = false          
            node

        ThisExpression: (node) ->
            super node
            node.__independent = false
            node.__hasThisExp = true
            node

        Identifier: (node) ->
            super node
            node.__independent = true
            node.__hasThisExp = false
            node

        MemberExpression: (node) ->
            super node
            ###
            # Undo independence of identifiers when they're members of this.* or
            # this.member.* (the latter allows for member functions)
            ###
            node.__hasThisExp = node.object?.__hasThisExp
            if(node.__hasThisExp)
                node.__independent = false
                node?.property.__independent = false

            node

        CallExpression: (node) ->
            super node
            node.__hasThisExp = node.callee.__hasThisExp

            node

        ObjectExpression: (node) ->
            super node
            
            ###
            # Prevent literal key identifiers from being evaluated out of
            # context
            ###
            for setter in node.properties
                setter.key.__independent = false

            ###
            # An object literal is independent if all of its values are
            # independent
            ###
            independence = true
            independence &= setter.value.__independent for setter in node.properties
            node.__independent = if independence then true else false

            node

        visit: (node) ->
            ###
            # Call the base visit method which will both visit all of our
            # subexpressions and also call the couple of overrides above which
            # handle the base independence cases
            ###
            super node

            ###
            # If the node's independence wasn't determined automatically by the
            # base cases above, then it's independence is determined by checking
            # all of its values and aggregating their independence
            ###
            if not (Object.prototype.hasOwnProperty.call(node, '__independent'))
                independence = true
                isIndependent = (node) ->
                    if _.isObject node then value.__independent ? false else true
                for name, value of node
                    if _.isArray value
                        independence &= (isIndependent v) for v in value
                    else if _.isObject value
                        independence &= (isIndependent value)
                ### &= will turn true/false into 1/0 so we'll turn it back ###
                node.__independent = if independence then true else false
            
            node
