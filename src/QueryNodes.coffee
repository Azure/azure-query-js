###
# ----------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# ----------------------------------------------------------------------------
###

###
# Define a low level intermediate query expression language that we can
# translate other expressions languages (like JavaScript) into.
###

### Get the base Node class. ###
{ Node, Visitor } = require('./Node')

###
# Provides the base class from which the classes that represent expression tree
# nodes are derived.
###
exports.QueryExpression =
    class QueryExpression extends Node
        constructor: ->
            super()

        ###
        # Group a sequence of clauses together with a given operator (like And
        # or Or).
        ###
        @groupClauses: (operator, clauses) ->
            combine = (left, right) ->
                if not left then right
                else if not right then left
                else new BinaryExpression(operator, left, right)
            clauses.reduce combine, null

exports.QueryExpressionVisitor =
    class QueryExpressionVisitor extends Visitor
        constructor: ->
            super()

        QueryExpression: (node) ->
            node

###
# Represents an expression that has a constant value.
###
exports.ConstantExpression =
    class ConstantExpression extends QueryExpression
        ###
        # @value: The value of the constant expression.
        ###
        constructor: (@value) ->
            super()

QueryExpressionVisitor::ConstantExpression = (node) ->
    @QueryExpression(node)

###
# Represents accessing a field.
###
exports.MemberExpression =
     class MemberExpression extends QueryExpression
        ###
        # @member: Gets the field to be accessed.
        ###
        constructor: (@member) ->
            super()

QueryExpressionVisitor::MemberExpression = (node) ->
    @QueryExpression(node)

###
# Represents an expression that has a binary operator.
###
exports.BinaryExpression =
    class BinaryExpression extends QueryExpression
        ###
        # @operator: The operator of the binary expression.
        # @left: The left operand of the binary operation.
        # @right: The right operand of the binary operation.
        ###
        constructor: (@operator, @left, @right) ->
            super()

QueryExpressionVisitor::BinaryExpression = (node) ->
    node = @QueryExpression(node)
    node.left = @visit(node.left)
    node.right = @visit(node.right)
    node

###
# Represents the known binary operators.
###
exports.BinaryOperators =
    And: 'And'
    Or: 'Or'
    Add: 'Add'
    Subtract: 'Subtract'
    Multiply: 'Multiply'
    Divide: 'Divide'
    Modulo: 'Modulo'
    GreaterThan: 'GreaterThan'
    GreaterThanOrEqual: 'GreaterThanOrEqual'
    LessThan: 'LessThan'
    LessThanOrEqual: 'LessThanOrEqual'
    NotEqual: 'NotEqual'
    Equal: 'Equal'

###
# Represents the known unary operators.
###
exports.UnaryExpression =
    class UnaryExpression extends QueryExpression
        ###
        # @operator: The operator of the unary expression.
        # @operand: The operand of the unary expression.
        ###
        constructor: (@operator, @operand) ->
            super()

QueryExpressionVisitor::UnaryExpression = (node) ->
    node = @QueryExpression(node)
    node.operand = @visit(node.operand)
    node

###
# Represents the known unary operators.
###
exports.UnaryOperators =
    Not: 'Not'
    Negate: 'Negate'
    Increment: 'Increment'
    Decrement: 'Decrement'

###
# Represents a method invocation.
###
exports.InvocationExpression =
    class InvocationExpression extends QueryExpression
        ###
        # @method: The name of the method to invoke.
        # @args: The arguments to the method.
        ###
        constructor: (@method, @args) ->
            super()

QueryExpressionVisitor::InvocationExpression = (node) ->
    node = @QueryExpression(node)
    node.args = @visit(node.args)
    node

###
# Represents the known unary operators.
###
exports.Methods =
    Length: 'Length'
    ToUpperCase: 'ToUpperCase'
    ToLowerCase: 'ToLowerCase'
    Trim: 'Trim'
    IndexOf: 'IndexOf'
    Replace: 'Replace'
    Substring: 'Substring'
    Concat: 'Concat'
    Day: 'Day'
    Month: 'Month'
    Year: 'Year' 
    Floor: 'Floor'
    Ceiling: 'Ceiling'
    Round: 'Round'

###
# Represents a literal string in the query language.
###
exports.LiteralExpression =
    class LiteralExpression extends QueryExpression
        ###
        # @queryString
        # @args
        ###
        constructor: (@queryString, @args = []) ->
            super()

QueryExpressionVisitor::LiteralExpression = (node) ->
    @QueryExpression(node)
