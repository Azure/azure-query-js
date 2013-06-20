###
# ----------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# ----------------------------------------------------------------------------
###


###
# Define the Esprima node structure for JavaScript parse trees.  This is mostly
# identical to the SpiderMonkey API defined at
# https://developer.mozilla.org/en/SpiderMonkey/Parser_API without any of the
# SpiderMonkey specifics and a few simplifications made by Esprima (i.e. it
# doesn't have separate objects for operator types, etc.).
#
# It's important to note that the Esprima parse tree will return object literals
# and not instances of these types.  They're provided primarily for reference
# and for easily constructing new subtrees during transformations by visitors.
###


### Get the base Node and Visitor classes. ###
{ Node, Visitor } = require './Node'

###
# Base node for all JavaScript nodes.
###
exports.JavaScriptNode =
    class JavaScriptNode extends Node
        constructor: ->
            super()

###
# Base visitor for all JavaScript nodes.
###
exports.JavaScriptVisitor =
    class JavaScriptVisitor extends Visitor
        constructor: ->
            super()

        JavaScriptNode: (node) ->
            node

###
# A complete program source tree.
###
exports.Program =
    class Program extends JavaScriptNode
        ###
        # @elements: [Statement]
        ###
        constructor: (@elements) ->
            super()

JavaScriptVisitor::Program = (node) ->
    node = @JavaScriptNode(node)
    node.elements = @visit(node.elements)
    node

###
# A function declaration or expression. The body of the function is a  block
# statement.
###
exports.Function =
    class Function extends JavaScriptNode
        ###
        # @id: Identifier | null
        # @params: [Pattern]
        # @body: BlockStatement
        ###
        constructor: (@id, @params, @body) ->
            super()

JavaScriptVisitor::Function = (node) ->
    node = @JavaScriptNode(node)
    node.id = @visit(node.id)
    node.params = @visit(node.params)
    node.body = @visit(node.body)
    node

###
# Any statement.
###
exports.Statement =
    class Statement extends JavaScriptNode
        constructor: ->
            super()

JavaScriptVisitor::Statement = (node) ->
    node = @JavaScriptNode(node)
    node

###
# An empty statement, i.e., a solitary semicolon.
###
exports.EmptyStatement =
    class EmptyStatement extends JavaScriptNode
        constructor: ->
            super()

JavaScriptVisitor::EmptyStatement = (node) ->
    node = @JavaScriptNode(node)
    node

###
# A block statement, i.e., a sequence of statements surrounded by braces.
###
exports.BlockStatement =
    class BlockStatement extends Statement
        ###
        # @body: [Statement]
        ###
        constructor: (@body) ->
            super()

JavaScriptVisitor::BlockStatement = (node) ->
    node = @Statement(node)
    node.body = @visit(node.body)
    node

###
# An expression statement, i.e., a statement consisting of a single expression.
###
exports.ExpressionStatement =
    class ExpressionStatement extends Statement
        constructor: ->
            super()

JavaScriptVisitor::ExpressionStatement = (node) ->
    node = @Statement(node)
    node

###
# An if statement.
###
exports.IfStatement =
    class IfStatement extends Statement
        ###
        # @test: Expression
        # @consequent: Statement
        # @alternate: Statement | null
        ###
        constructor: (@test, @consequent, @alternate) ->
            super()

JavaScriptVisitor::IfStatement = (node) ->
    node = @Statement(node)
    node.test = @visit(node.test)
    node.consequent = @visit(node.consequent)
    node.alternate = @visit(node.alternate)
    node

###
# A labeled statement, i.e., a statement prefixed by a break/continue label.
###
exports.LabeledStatement =
    class LabeledStatement extends Statement
        ###
        # @label: Identifier
        # @body: Statement
        ###
        constructor: (@label, @body) ->
            super()

JavaScriptVisitor::LabeledStatement = (node) ->
    node = @Statement(node)
    node.label = @visit(node.label)
    node.body = @visit(node.body)
    node

###
# A break statement.
###
exports.BreakStatement =
    class BreakStatement extends Statement
        ###
        # @label: Identifier | null
        ###
        constructor: (@label) ->
            super()

JavaScriptVisitor::BreakStatement = (node) ->
    node = @Statement(node)
    node.label = @visit(node.label)
    node

###
A continue statement.
###
exports.ContinueStatement =
    class ContinueStatement extends Statement
        ###
        @label: Identifier | null
        ###
        constructor: (@label) ->
            super()

JavaScriptVisitor::ContinueStatement = (node) ->
    node = @Statement(node)
    node.label = @visit(node.label)
    node

###
# A with statement.
###
exports.WithStatement =
    class WithStatement extends Statement
        ###
        # @object: Expression
        # @body: Statement
        ###
        constructor: (@object, @body) ->
            super()

JavaScriptVisitor::WithStatement = (node) ->
    node = @Statement(node)
    node.object = @visit(node.object)
    node.body = @visit(node.body)
    node

###
# A switch statement.
###
exports.SwitchStatement =
    class SwitchStatement extends Statement
        ###
        # @discriminant: Expression
        # @cases: [SwitchCase]
        ###
        constructor: (@discriminant, @cases) ->
            super()

JavaScriptVisitor::SwitchStatement = (node) ->
    node = @Statement(node)
    node.discriminant = @visit(node.discriminant)
    node.cases = @visit(node.cases)
    node

###
# A return statement.
###
exports.ReturnStatement =
    class ReturnStatement extends Statement
        ###
        # @argument: Expression | null
        ###
        constructor: (@argument) ->
            super()

JavaScriptVisitor::ReturnStatement = (node) ->
    node = @Statement(node)
    node.argument = @visit(node.argument)
    node

###
# A throw statement.
###
exports.ThrowStatement =
    class ThrowStatement extends Statement
        ###
        # @argument: Expression
        ###
        constructor: (@argument) ->
            super()

JavaScriptVisitor::ThrowStatement = (node) ->
    node = @Statement(node)
    node.argument = @visit(node.argument)
    node

###
# A try statement.
###
exports.TryStatement =
    class TryStatement extends Statement
        ###
        # @block: BlockStatement
        # @handlers: [CatchClause]
        # @finalizer: BlockStatement | null
        ###
        constructor: (@block, @handlers, @finalizer) ->
            super()

JavaScriptVisitor::TryStatement = (node) ->
    node = @Statement(node)
    node.block = @visit(node.block)
    node.handlers = @visit(node.handlers)
    node.finalizer = @visit(node.finalizer)
    node

###
# A while statement.
###
exports.WhileStatement =
    class WhileStatement extends Statement
        ###
        # @test: Expression
        # @body: Statement
        ###
        constructor: (@test, @body) ->
            super()

JavaScriptVisitor::WhileStatement = (node) ->
    node = @Statement(node)
    node.test = @visit(node.test)
    node.body = @visit(node.body)
    node

###
# A do/while statement.
###
exports.DoWhileStatement =
    class DoWhileStatement extends Statement
        ###
        # @body: Statement
        # @test: Expression
        ###
        constructor: (@body, @test) ->
            super()

JavaScriptVisitor::DoWhileStatement = (node) ->
    node = @Statement(node)
    node.body = @visit(node.body)
    node.test = @visit(node.test)
    node

###
# A for statement.
###
exports.ForStatement =
    class ForStatement extends Statement
        ###
        # @init: VariableDeclaration | Expression | null
        # @test: Expression | null
        # @update: Expression | null
        # @body: Statement
        ###
        constructor: (@init, @test, @update, @body) ->
            super()

JavaScriptVisitor::ForStatement = (node) ->
    node = @Statement(node)
    node.init = @visit(node.init)
    node.test = @visit(node.test)
    node.update = @visit(node.update)
    node.body = @visit(node.body)
    node

###
# A for/in statement, or, if each is true, a for each/in statement.
###
exports.ForInStatement =
    class ForInStatement extends Statement
        ###
        # @left: VariableDeclaration |  Expression
        # @right: Expression
        # @body: Statement
        ###
        constructor: (@left, @right, @body) ->
            super()

JavaScriptVisitor::ForInStatement = (node) ->
    node = @Statement(node)
    node.left = @visit(node.left)
    node.right = @visit(node.right)
    node.body = @visit(node.body)
    node

###
# A debugger statement.
###
exports.DebuggerStatement =
    class DebuggerStatement extends Statement
        constructor: ->
            super()

JavaScriptVisitor::DebuggerStatement = (node) ->
    node = @Statement(node)
    node

###
# Any declaration node. Note that declarations are considered statements; this
# is because declarations can appear in any statement context in the language.
###
exports.Declaration =
    class Declaration extends Statement
        constructor: ->
            super()

JavaScriptVisitor::Declaration = (node) ->
    node = @Statement(node)
    node

###
# A function declaration.  Note: The id field cannot be null.
###
exports.FunctionDeclaration =
    class FunctionDeclaration extends Declaration #, Function
        ###
        # @id: Identifier
        # @params: [ Pattern ]
        # @body: BlockStatement | Expression
        ###
        constructor: (@id, @params, @body) ->
            super()

JavaScriptVisitor::FunctionDeclaration = (node) ->
    node = @Declaration(node)
    node.id = @visit(node.id)
    node.params = @visit(node.params)
    node.body = @visit(node.body)
    node

###
# A variable declaration, via one of var, let, or const.
###
exports.VariableDeclaration =
    class VariableDeclaration extends Declaration
        ###
        # @declarations: [ VariableDeclarator ]
        # @kind: "var"
        ###
        constructor: (@declarations, @kind) ->
            super()

JavaScriptVisitor::VariableDeclaration = (node) ->
    node = @Declaration(node)
    node.declarations = @visit(node.declarations)
    node

###
# A variable declarator.  Note: The id field cannot be null.
###
exports.VariableDeclarator =
    class VariableDeclarator extends JavaScriptNode
        ###
        # @id: Pattern
        # @init: Expression | null
        ###
        constructor: (@id, @init) ->
            super()

JavaScriptVisitor::VariableDeclarator = (node) ->
    node = @JavaScriptNode(node)
    node.id = @visit(node.id)
    node.init = @visit(node.init)
    node

###
# Any expression node. Since the left-hand side of an assignment may be any
# expression in general, an expression can also be a pattern.
###
exports.Expression =
    class Expression extends JavaScriptNode #, Pattern
        constuctor: ->
            super()

JavaScriptVisitor::Expression = (node) ->
    node = @JavaScriptNode(node)
    node

###
# A this expression.
###
exports.ThisExpression =
    class ThisExpression extends Expression
        constructor: ->
            super()

JavaScriptVisitor::ThisExpression = (node) ->
    node = @Expression(node)
    node

###
# An array expression.
###
exports.ArrayExpression =
    class ArrayExpression extends Expression
        ###
        # @elements: [ Expression | null ]
        ###
        constructor: (@elements) ->
            super()

JavaScriptVisitor::ArrayExpression = (node) ->
    node = @Expression(node)
    node.elements = @visit(node.elements)
    node

###
# An object expression. A literal property in an object expression can have
# either a string or number as its value.  Ordinary property initializers have a
# kind value "init"; getters and setters have the kind values "get" and "set",
# respectively.
###
exports.ObjectExpression =
    class ObjectExpression extends Expression
        ###
        # @properties: [ { key: Literal | Identifier,
        #                 value: Expression,
        #                 kind: "init" | "get" | "set" } ];
        ###
        constructor: (@properties) ->
            super()

JavaScriptVisitor::ObjectExpression = (node) ->
    node = @Expression(node)
    for setter in node.properties
        setter.key = @visit(setter.key)
        setter.value = @visit(setter.value)
    node

###
# A function expression.
###
exports.FunctionExpression =
    class FunctionExpression extends Expression
        ###
        # @id: Identifier | null
        # @params: [ Pattern ]
        # @body: BlockStatement | Expression
        ###
        constructor: (@id, @params, @body) ->
            super()

JavaScriptVisitor::FunctionExpression = (node) ->
    node = @Expression(node)
    node.id = @visit(node.id)
    node.params = @visit(node.params)
    node.body = @visit(node.body)
    node

###
# A sequence expression, i.e., a comma-separated sequence of expressions.
###
exports.SequenceExpression =
    class SequenceExpression extends Expression
        ###
        # @expressions: [ Expression ]
        ###
        constructor: (@expressions) ->
            super()

JavaScriptVisitor::SequenceExpression = (node) ->
    node = @Expression(node)
    node.expressions = @visit(node.expressions)
    node

###
# A unary operator expression.
###
exports.UnaryExpression =
    class UnaryExpression extends Expression
        ###
        # @operator: "-" | "+" | "!" | "~" | "typeof" | "void" | "delete"
        # @prefix: boolean
        # @argument: Expression
        ###
        constructor: (@operator, @prefix, @argument) ->
            super()

JavaScriptVisitor::UnaryExpression = (node) ->
    node = @Expression(node)
    node.argument = @visit(node.argument)
    node

###
# A binary operator expression.
###
exports.BinaryExpression =
    class BinaryExpression extends Expression
        ###
        # @operator: "==" | "!=" | "===" | "!==" | "<" | "<=" | ">" | ">="
        #     | "<<" | ">>" | ">>>" | "+" | "-" | "*" | "/" | "%"
        #     | "|" | "&" | "^" | "in" | "instanceof" | ".."
        # @left: Expression
        # @right: Expression
        ###
        constructor: (@operator, @left, @right) ->
            super()

JavaScriptVisitor::BinaryExpression = (node) ->
    node = @Expression(node)
    node.left = @visit(node.left)
    node.right = @visit(node.right)
    node

###
# An assignment operator expression.
###
exports.AssignmentExpression =
    class AssignmentExpression extends Expression
        ###
        # @operator: "=" | "+=" | "-=" | "*=" | "/=" | "%="
        #     | "<<=" | ">>=" | ">>>=" | "|=" | "^=" | "&=";
        # @left: Expression
        # @right: Expression
        ###
        constructor: (@operator, @left, @right) ->
            super()

JavaScriptVisitor::AssignmentExpression = (node) ->
    node = @Expression(node)
    node.left = @visit(node.left)
    node.right = @visit(node.right)
    node

###
# An update (increment or decrement) operator expression.
###
exports.UpdateExpression =
    class UpdateExpression extends Expression
        ###
        # @operator: "++" | "--"
        # @argument: Expression
        # @prefix: boolean
        ###
        constructor: (@operator, @argument, @prefix) ->
            super()

JavaScriptVisitor::UpdateExpression = (node) ->
    node = @Expression(node)
    node.argument = @visit(node.argument)
    node

###
# A logical operator expression.
###
exports.LogicalExpression =
    class LogicalExpression extends Expression
        ###
        # @operator: "||" | "&&"
        # @left: Expression
        # @right: Expression
        ###
        constructor: (@operator, @left, @right) ->
            super()

JavaScriptVisitor::LogicalExpression = (node) ->
    node = @Expression(node)
    node.left = @visit(node.left)
    node.right = @visit(node.right)
    node

###
# A conditional expression, i.e., a ternary ?/: expression.
###
exports.ConditionalExpression =
    class ConditionalExpression extends Expression
        ###
        # @test: Expression
        # @alternate: Expression
        # @consequent: Expression
        ###
        constructor: (@test, @alternate, @consequent) ->
            super()

JavaScriptVisitor::ConditionalExpression = (node) ->
    node = @Expression(node)
    node.test = @visit(node.test)
    node.alternate = @visit(node.alternate)
    node.consequent = @visit(node.consequent)
    node

###
# A new expression.
###
exports.NewExpression =
    class NewExpression extends Expression
        ###
        # @callee: Expression
        # @arguments: [ Expression ] | null
        ###
        constructor: (@callee, @arguments) ->
            super()

JavaScriptVisitor::NewExpression = (node) ->
    node = @Expression(node)
    node.callee = @visit(node.callee)
    node.arguments = @visit(node.arguments)
    node

###
# A function or method call expression.
###
exports.CallExpression =
    class CallExpression extends Expression
        ###
        # @callee: Expression
        # @arguments: [ Expression ]
        ###
        constructor: (@callee, @arguments) ->
            super()

JavaScriptVisitor::CallExpression = (node) ->
    node = @Expression(node)
    node.callee = @visit(node.callee)
    node.arguments = @visit(node.arguments)
    node

###
# A member expression. If computed === true, the node corresponds to a computed
# e1[e2] expression and property is an Expression. If computed === false, the
# node corresponds to a static e1.x expression and property is an Identifier.
###
exports.MemberExpression =
    class MemberExpression extends Expression
        ###
        # @object: Expression
        # @property: Identifier | Expression
        # @computed : boolean
        ###
        constructor: (@object, @property, @computed) ->
            super()

JavaScriptVisitor::MemberExpression = (node) ->
    node = @Expression(node)
    node.object = @visit(node.object)
    node.property = @visit(node.property)
    node

###
# JavaScript 1.7 introduced destructuring assignment and binding forms.  All
# binding forms (such as function parameters, variable declarations, and catch
# block headers), accept array and object destructuring patterns in addition to
# plain identifiers. The left-hand sides of assignment expressions can be
# arbitrary expressions, but in the case where the expression is an object or
# array literal, it is interpreted by SpiderMonkey as a destructuring pattern.
#
# Since the left-hand side of an assignment can in general be any expression, in
# an assignment context, a pattern can be any expression. In binding positions
# (such as function parameters, variable declarations, and catch headers),
# patterns can only be identifiers in the base case, not arbitrary expressions.
###
exports.Pattern =
    class Pattern extends JavaScriptNode
        constructor: ->
            super()

JavaScriptVisitor::Pattern = (node) ->
    node = @JavaScriptNode(node)
    node

###
# An object-destructuring pattern. A literal property in an object pattern can
# have either a string or number as its value.
###
exports.ObjectPattern =
    class ObjectPattern extends Pattern
        ###
        # @properties: [ { key: Literal | Identifier, value: Pattern } ]
        ###
        constructor: (@properties) ->
            super()

JavaScriptVisitor::ObjectPattern = (node) ->
    node = @Pattern(node)
    for setter in node.properties
        setter.key = @visit(setter.key)
        setter.value = @visit(setter.value)
    node

###
# An array-destructuring pattern.
###
exports.ArrayPattern =
    class ArrayPattern extends Pattern
        ###
        # @elements: [ Pattern | null ]
        ###
        constructor: (@elements) ->
            super()

JavaScriptVisitor::ArrayPattern = (node) ->
    node = @Pattern(node)
    node.elements = @visit(node.elements)
    node

###
# A case (if test is an Expression) or default (if test === null) clause in the
# body of a switch statement.
###
exports.SwitchCase =
    class SwitchCase extends JavaScriptNode
        ###
        # @test: Expression | null
        # @consequent: [ Statement ]
        ###
        constructor: (@test, @consequent) ->
            super()

JavaScriptVisitor::SwitchCase = (node) ->
    node = @JavaScriptNode(node)
    node.test = @visit(node.test)
    node.consequent = @visit(node.consequent)
    node

###
# A catch clause following a try block. The optional guard property corresponds
# to the optional expression guard on the bound variable.
###
exports.CatchClause =
    class CatchClause extends JavaScriptNode
        ###
        # @param: Pattern
        # @body: BlockStatement
        ###
        constructor: (@param, @body) ->
            super()

JavaScriptVisitor::CatchClause = (node) ->
    node = @JavaScriptNode(node)
    node.param = @visit(node.param)
    node.body = @visit(node.body)
    node

###
# An identifier. Note that an identifier may be an expression or a destructuring
# pattern.
###
exports.Identifier =
    class Identifier extends JavaScriptNode
        ###
        # @name: string
        ###
        constructor: (@name) ->
            super()

JavaScriptVisitor::Identifier = (node) ->
    node = @JavaScriptNode(node)
    node

###
# A literal token. Note that a literal can be an expression.
###
exports.Literal =
    class Literal extends Expression
        ###
        # @value: string | boolean | null | number | RegExp
        ###
        constructor: (@value) ->
            super()

JavaScriptVisitor::Literal = (node) ->
    node = @Expression(node)
    node
