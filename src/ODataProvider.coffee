###
# ----------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# ----------------------------------------------------------------------------
###

_ = require './Utilities'
Q = require './QueryNodes'
{ Query } = require './Query'

exports.ODataProvider =
    class ODataProvider
        ###
        # Convert a query into an OData URI.
        ###
        toQuery: (query) ->
            odata = @toOData query, true
            url = "/#{odata.table}"
            s = '?'
            if odata.filters
                url += "#{s}$filter=#{odata.filters}"
                s = '&'
            if odata.orderClauses
                url += "#{s}$orderby=#{odata.orderClauses}"
                s = '&'
            if odata.skip
                url += "#{s}$skip=#{odata.skip}"
                s = '&'
            if odata.take || odata.take == 0
                url += "#{s}$top=#{odata.take}"
                s = '&'
            if odata.selections
                url += "#{s}$select=#{odata.selections}"
                s = '&'
            if odata.includeTotalCount
                url += "#{s}$inlinecount=allpages"

            # includeDeleted is not standard odata, it is used by azure-mobile-apps
            if odata.includeDeleted
                url += "#{s}__includeDeleted=true"
            url

        ###
        # Translate the query components into OData strings
        ###
        toOData: (query, encodeForUri) ->
            if not encodeForUri?
                encodeForUri = false;
            components = query?.getComponents() ? { }
            ordering = ((if asc then name else "#{name} desc") for name, asc of components?.ordering)
            orderClauses = ((if order.ascending then order.name else "#{order.name} desc") for order in components?.orderClauses)
            odata =
                table: components?.table
                filters: ODataFilterQueryVisitor.convert components.filters, encodeForUri
                ordering: ordering?.toString()
                orderClauses: orderClauses?.toString()
                skip: components?.skip
                take: components?.take
                selections: components?.selections?.toString()
                includeTotalCount: components?.includeTotalCount
                includeDeleted: components?.includeDeleted

        ###
        # Convert OData components into a query object
        ###
        fromOData: (table, filters, ordering, skip, take, selections, includeTotalCount, includeDeleted) ->
            query = new Query(table)
            query.where filters if filters
            query.skip skip if skip || skip == 0
            query.take take if take || take == 0
            query.includeTotalCount() if includeTotalCount
            query.includeDeleted() if includeDeleted
            (query.select field.trim()) for field in (selections?.split(',') ? [])
            for [field, direction] in (item.trim().split ' ' for item in (ordering?.split(',') ? []))
                if direction?.toUpperCase() != 'DESC'
                    query.orderBy field
                else
                    query.orderByDescending field
            query

###
# Visitor that converts query expression trees into OData filter statements.
###
class ODataFilterQueryVisitor extends Q.QueryExpressionVisitor

    constructor: (@encodeForUri) ->

    @convert: (filters, encodeForUri) ->
        visitor = new ODataFilterQueryVisitor encodeForUri
        (visitor.visit(filters) if filters) ? null

    toOData: (value) ->
        if (_.isNumber value) || (_.isBoolean value)
            value.toString()
        else if _.isString value
            value = value.replace /'/g, "''"
            if (@encodeForUri? && @encodeForUri is true)
                value = encodeURIComponent(value);
            "'#{value}'"
        else if _.isDate value
            ###
            # Dates are expected in the format
            #   "datetime'yyyy-mm-ddThh:mm[:ss[.fffffff]]'"
            # which JSON.stringify gives us by default
            ###
            text = JSON.stringify value
            if text.length > 2
                text = text[1..text.length-2]
            # IE8's JSON.stringify omits decimal part from dates,
            # so insert it manually if missing
            text = text.replace /(T\d{2}:\d{2}:\d{2})Z$/, (all, time) ->
                msec = String(value.getMilliseconds() + 1000).substring(1)
                "#{time}.#{msec}Z"
            "datetime'#{text}'"
        else if not value
            "null"
        else
            throw "Unsupported literal value #{value}"

    ConstantExpression: (node) ->
        @toOData node.value

    MemberExpression: (node) ->
        node.member

    UnaryExpression: (node) ->
        if node.operator == Q.UnaryOperators.Not
            "not #{@visit node.operand}"
        else if node.operator == Q.UnaryOperators.Negate
            "(0 sub #{@visit node.operand})"
        else
            throw "Unsupported operator #{node.operator}"

    BinaryExpression: (node) ->
        mapping =
            And: 'and'
            Or: 'or'
            Add: 'add'
            Subtract: 'sub'
            Multiply: 'mul'
            Divide: 'div'
            Modulo: 'mod'
            GreaterThan: 'gt'
            GreaterThanOrEqual: 'ge'
            LessThan: 'lt'
            LessThanOrEqual: 'le'
            NotEqual: 'ne'
            Equal: 'eq'
        op = mapping[node.operator]
        if op
            "(#{@visit node.left} #{op} #{@visit node.right})"
        else
            throw "Unsupported operator #{node.operator}"

    InvocationExpression: (node) ->
        mapping =
            Length: 'length'
            ToUpperCase: 'toupper'
            ToLowerCase: 'tolower'
            Trim: 'trim'
            IndexOf: 'indexof'
            Replace: 'replace'
            Substring: 'substring'
            Concat: 'concat'
            Day: 'day'
            Month: 'month'
            Year: 'year'
            Floor: 'floor'
            Ceiling: 'ceiling'
            Round: 'round'
        method = mapping[node.method]
        if method
            "#{method}(#{@visit(node.args)})"
        else
            throw "Invocation of unsupported method #{node.method}"

    LiteralExpression: (node) ->
        literal = ''
        parenBalance = 0
        inString = false
        for ch in node.queryString
            if parenBalance < 0
                break                
            else if inString
                literal += ch
                inString = ch != "'"
            else if ch == '?'
                if (not node.args) || (node.args.length <= 0)
                    throw "Too few arguments for #{node.queryString}."
                literal += @toOData(node.args.shift())
            else if ch == "'"
                literal += ch
                inString = true
            else if ch == '('
                parenBalance += 1;
                literal += ch
            else if ch == ')'
                parenBalance -= 1;
                literal += ch
            else
                literal += ch
        if node.args && node.args.length > 0
            throw "Too many arguments for #{node.queryString}"
        if parenBalance != 0
            throw "Unbalanced parentheses in #{node.queryString}"
        if literal.trim().length > 0
            "(#{literal})"
        else
            literal