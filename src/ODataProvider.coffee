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
Q = require './QueryNodes'
{ Query } = require './Query'

exports.ODataProvider =
    class ODataProvider
        ###
        # Convert a query into an OData URI.
        ###
        toQuery: (query) ->
            odata = @toOData query
            url = "/#{odata.table}"
            s = '?'
            if odata.filters
                url += "#{s}$filter=#{odata.filters}"
                s = '&'
            if odata.ordering
                url += "#{s}$orderby=#{odata.ordering}"
                s = '&'
            if odata.skip
                url += "#{s}$skip=#{odata.skip}"
                s = '&'
            if odata.take
                url += "#{s}$top=#{odata.take}"
                s = '&'
            if odata.selections
                url += "#{s}$select=#{odata.selections}"
                s = '&'
            if odata.includeTotalCount
                url += "#{s}$inlinecount=allpages"
            url

        ###
        # Translate the query components into OData strings
        ###
        toOData: (query) ->
            components = query?.getComponents() ? { }
            ordering = ((if asc then name else "#{name} desc") for name, asc of components?.ordering)
            odata =
                table: components?.table
                filters: ODataFilterQueryVisitor.convert components.filters
                ordering: ordering?.toString()
                skip: components?.skip
                take: components?.take
                selections: components?.selections?.toString()
                includeTotalCount: components?.includeTotalCount

        ###
        # Convert OData components into a query object
        ###
        fromOData: (table, filters, ordering, skip, take, selections, includeTotalCount) ->
            query = new Query(table)
            query.where filters if filters
            query.skip skip if skip || skip == 0
            query.take take if take || take == 0
            query.includeTotalCount() if includeTotalCount
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
    @convert: (filters) ->
        visitor = new ODataFilterQueryVisitor
        (visitor.visit(filters) if filters) ? null

    toOData: (value) ->
        if (_.isNumber value) || (_.isBoolean value)
            value.toString()
        else if _.isString value
            value = value.replace /'/g, "''"
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
        inString = false
        for ch in node.queryString
            if inString
                literal += ch
                inString = ch != "'"
            else if ch == '?'
                if (not node.args) || (node.args.length <= 0)
                    throw "Too few arguments for #{node.queryString}."
                literal += @toOData(node.args.shift())
            else if ch == "'"
                literal += ch
                inString = true
            else
                literal += ch
        if node.args && node.args.length > 0
            throw "Too many arguments for #{node.queryString}"
        literal