###
# ----------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# ----------------------------------------------------------------------------
###


esprima = require 'esprima'
JS = require './JavaScriptNodes'
{ PartialEvaluator } = require './PartialEvaluator'
{ JavaScriptToQueryVisitor } = require './JavaScriptToQueryVisitor'

###
# Define operations on JavaScript
###
exports.JavaScript =
    class JavaScript
        ###
        # Static method to transform a constraint specified as a function into
        # a QueryExpression tree.
        ###
        @transformConstraint: (func, env) ->
            ###
            # Parse the body of the function into a JavaScriptExpression tree
            # (into a context that also contains its source and manually reified
            # environment)
            ###
            context = JavaScript.getExpression func, env

            ###
            # Evaluate any independent subexpressions and turn them into
            # literals.
            ###
            context.expression = PartialEvaluator.evaluate context

            ###
            # Convert the JavaScriptExpression tree into a QueryExpression tree
            ###
            translator = new JavaScriptToQueryVisitor context
            translator.visit context.expression

        ###
        # Static method to walk a projection specified as a function and
        # determine which fields it uses.
        ###
        @getProjectedFields: (func) ->
            ###
            # This currently returns an empty array which indicates all fields.
            # At some point we'll need to go through and walk the expression
            # tree for func and see exactly which fields it uses.  This is
            # complicated by the fact that we support arbitrary expressions and
            # could for example pass 'this' to a nested lambda which means we
            # can't just check for MemberExpressions (though in that case we'll
            # probably just default to [] rather than trying to do alias
            # analysis across function calls, etc.)
            ###
            []

        ###
        # Turn a function and its explicitly passed environment into an
        # expression tree
        ###
        @getExpression = (func, env) ->
            ###
            # An anonymous function isn't considered a valid program, so we'll wrap
            # it in an assignment statement to keep the parser happy
            ###
            source = "var _$$_stmt_$$_ = #{func};"

            ###
            # Use esprima to parse the source of the function body (and have it
            # return source locations in character ranges )
            ###
            program = esprima.parse source, range: true

            ###
            # Get the expression from return statement of the function body to use
            # as our lambda expression
            ###
            expr =
                program?.type == 'Program' &&
                program?.body?.length == 1 &&
                program.body[0]?.type == 'VariableDeclaration' &&
                program.body[0]?.declarations?.length == 1 &&
                program.body[0].declarations[0]?.type == 'VariableDeclarator' &&
                program.body[0].declarations[0]?.init?.type == 'FunctionExpression' &&
                program.body[0].declarations[0].init?.body?.type == 'BlockStatement' &&
                program.body[0].declarations[0].init.body?.body?.length == 1 &&
                program.body[0].declarations[0].init.body.body[0]?.type == 'ReturnStatement' &&
                program.body[0].declarations[0].init.body.body[0]?.argument;
            if not expr
                throw "Expected a predicate with a single return statement, not #{func}"

            ###
            # Create the environment mqpping parameters to values
            ###
            names = program.body[0].declarations[0].init.params?.map (p) -> p.name
            if names.length > env.length
                throw "Expected value(s) for parameter(s) #{names[env.length..]}"
            else if env.length > names.length
                throw "Expected parameter(s) for value(s) #{env[names.length..]}"
            environment = { }
            for name, i in names
                environment[name] = env[i]

            ###
            # Return the environment context
            ###
            source : source,
            expression : expr,
            environment : environment
