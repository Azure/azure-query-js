###
# ----------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# ----------------------------------------------------------------------------
###


### Pull in references ###
_ = require './Utilities'
Q = require './QueryNodes'
{ JavaScript } = require './JavaScript'


###
# Define a query that can be translated into a desired query language and
# executed remotely.
###
exports.Query =
    class Query
        constructor: (table, context) ->
            if not table or not (_.isString table)
                throw 'Expected the name of a table!'

            ### Store the table name and any extra context ###
            _table = table
            _context = context

            ### Private Query component members ###
            _filters = null
            _projection = null
            _selections = []
            # Ordering is maintained for backward compatibility,
            #  but it's not used for generating the OData query
            _ordering = {}
            _orderClauses = []
            _skip = null
            _take = null
            _includeTotalCount = false
            _includeDeleted = false

            ###
            # Keep a version flag that's updated on each mutation so we can
            # track whether changes have been made.  This is to enable caching
            # of compiled queries without reevaluating unless necessary.
            ###
            _version = 0

            ### Get the individual components of the query ###
            @getComponents = ->
                filters: _filters
                selections: _selections
                projection: _projection
                ordering: _ordering
                orderClauses: _orderClauses
                skip: _skip
                take: _take
                table: _table
                context: _context
                includeTotalCount: _includeTotalCount
                includeDeleted: _includeDeleted
                version: _version

            ###
            # Set the individual components of the query (this is primarily
            # meant to be used for rehydrating a query).
            ###
            @setComponents = (components) ->
                _version++
                _filters = components?.filters ? null
                _selections = components?.selections ? []
                _projection = components?.projection ? null
                _skip = components?.skip ? null
                _take = components?.take ? null
                _includeTotalCount = components?.includeTotalCount ? false
                _includeDeleted = components?.includeDeleted ? false
                _table = components?.table ? null
                _context = components?.context ? null
                if components?.orderClauses
                    _orderClauses = components?.orderClauses ? []
                    _ordering = {}
                    _ordering[name] = ascending for { name, ascending } in _orderClauses
                else
                    _ordering = components?.ordering ? {}
                    _orderClauses = []
                    for property of _ordering
                        _orderClauses.push({ name: property, ascending: !!_ordering[property] })
                this


            ###
            # Add a constraint to a query.  Constraints can take the form of
            # a function with a single return statement, key/value pairs of
            # equality comparisons, or provider-specific literal strings (note
            # that not all providers support literals).
            ###
            @where = (constraint, args...) ->
                _version++
                ###
                # Translate the constraint from its high level form into a
                # QueryExpression tree that can be manipulated by a query
                # provider
                ###
                expr =
                    if _.isFunction constraint
                        JavaScript.transformConstraint constraint, args
                    else if _.isObject constraint
                        ###
                        # Turn an object of key value pairs into a series of
                        # equality expressions that are and'ed together to form
                        # a single expression
                        ###
                        Q.QueryExpression.groupClauses Q.BinaryOperators.And,
                            for name, value of constraint
                                expr = new Q.BinaryExpression(
                                    Q.BinaryOperators.Equal,
                                    new Q.MemberExpression(name),
                                    new Q.ConstantExpression(value))
                    else if _.isString constraint
                        ###
                        # Store the literal query along with any arguments for
                        # providers that support basic string replacement (i.e.,
                        # something like where('name eq ?', 'Steve'))
                        ###
                        new Q.LiteralExpression constraint, args
                    else
                        throw "Expected a function, object, or string, not #{constraint}"

                ### Merge the new filters with any existing filters ###
                _filters = Q.QueryExpression.groupClauses Q.BinaryOperators.And, [_filters, expr]
                this

            ###
            # Project the query results.  A projection can either be defined as
            # a set of fields that we'll pull back (instead of the entire row)
            # or a function that will transform a row into a new type.  If a
            # function is used, we'll analyze the function to pull back the
            # minimal number of fields required.
            ###
            @select = (projectionOrParameter, parameters...) ->
                _version++
                if _.isString projectionOrParameter
                    ### Add all the literal string parameters ###
                    _selections.push(projectionOrParameter)
                    for param in parameters
                        if not (_.isString param)
                            throw "Expected string parameters, not #{param}"
                        _selections.push(param)
                else if _.isFunction projectionOrParameter
                    ### Set the projection and calculate the fields it uses ###
                    _projection = projectionOrParameter
                    _selections = JavaScript.getProjectedFields _projection
                else
                    throw "Expected a string or a function, not #{projectionOrParameter}"
                this

            @orderBy = (parameters...) ->
                _version++
                for param in parameters
                    if not (_.isString param)
                        throw "Expected string parameters, not #{param}"
                    _ordering[param] = true
                    replacement = false
                    for order in _orderClauses
                        if order.name == param
                            replacement = true
                            order.ascending = true
                    if not replacement
                        _orderClauses.push({ name: param, ascending: true })
                this

            @orderByDescending = (parameters...) ->
                _version++
                for param in parameters
                    if not (_.isString param)
                        throw "Expected string parameters, not #{param}"
                    _ordering[param] = false
                    replacement = false
                    for order in _orderClauses
                        if order.name == param
                            replacement = true
                            order.ascending = false
                    if not replacement
                        _orderClauses.push({ name: param, ascending: false })
                this

            @skip = (count) ->
                _version++
                if not (_.isNumber count)
                    throw "Expected a number, not #{count}"
                _skip = count
                this

            @take = (count) ->
                _version++
                if not (_.isNumber count)
                    throw "Expected a number, not #{count}"
                _take = count
                this

            ###
            # Indicate that the query should include the total count for all the
            # records that would have been returned ignoring any take paging
            # limit clause specified by client or server.
            ###
            @includeTotalCount = () ->
                _version++
                _includeTotalCount = true
                this

            ###
            # Indicate that the query should include soft deleted records.
            ###
            @includeDeleted = () ->
                _version++
                _includeDeleted = true
                this

        ###
        # Static method to register custom provider types.  A custom provider is
        # an object with a toQuery method that takes a Query instance and
        # returns a compiled query for that provider.
        ###
        @registerProvider: (name, provider) ->
            Query.Providers[name] = provider
            Query::["to#{name}"] = ->
                provider?.toQuery?(this)

        ###
        # Expose the registered providers via the Query.Providers namespace.
        ###
        @Providers : { }

        ###
        # Expose the query expressions and visitors externally via a
        # Query.Expressions namespace.
        ###
        @Expressions : Q

### Register the built in OData provider ###
{ ODataProvider } = require './ODataProvider'
Query.registerProvider 'OData', new ODataProvider
