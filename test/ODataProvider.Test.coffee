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

{ Query } = require '../lib/Query'
assert = require 'assert'

suite 'ODataProvider'

translate = (odata, query) ->
    test odata, ->
        assert.equal query.toOData(), odata

translate "/basics",
    new Query('basics')

translate "/basics?$filter=(price eq 12)",
    new Query('basics').where(price: 12)

translate "/basics?$filter=(price eq 13)",
    new Query('basics').where(-> @price == 13)

translate "/basics?$filter=(price eq 14)",
    new Query('basics').where(-> @price == 14)

translate "/customers?$filter=(name eq 'Bob')",
    new Query('customers').where(name: 'Bob')

translate "/basics?$filter=(price eq null)",
    new Query('basics').where(price: null)

translate "/basics?$filter=(price eq null)",
    new Query('basics').where(-> @price == null)

translate "/types?$filter=(price eq 8)",
    new Query('types').where(price: 8)

translate "/types?$filter=(price eq 9)",
    new Query('types').where(-> @price == 9)

translate "/types?$filter=(price eq -8)",
    new Query('types').where(price: -8)

translate "/types?$filter=(price eq -9)",
    new Query('types').where(-> @price == -9)

translate "/types?$filter=(price eq 0.5)",
    new Query('types').where(price: .5)

translate "/types?$filter=(price eq 0.6)",
    new Query('types').where(-> @price == .6)

translate "/types?$filter=(inStock eq true)",
    new Query('types').where(inStock: true)

translate "/types?$filter=(inStock eq true)",
    new Query('types').where(-> @inStock == true)

translate "/types?$filter=(inStock eq false)",
    new Query('types').where(inStock: false)

translate "/types?$filter=(inStock eq false)",
    new Query('types').where(-> @inStock == false)

translate "/types?$filter=(author eq 'John')",
    new Query('types').where(author: 'John')

translate "/types?$filter=(author eq 'John')",
    new Query('types').where(-> @author == 'John')

translate "/types?$filter=(author eq 'John')",
    new Query('types').where(author: "John")

translate "/types?$filter=(author eq 'John')",
    new Query('types').where(-> @author == "John")

translate "/types?$filter=(author eq 'John%20Doe')",
    new Query('types').where(author: "John Doe")

translate "/types?$filter=(author eq 'John%20Doe')",
    new Query('types').where(-> @author == "John Doe")

translate "/types?$filter=(author eq 'escapes%20''s')",
    new Query('types').where(author: "escapes 's")

translate "/types?$filter=(author eq 'escapes%20''s')",
    new Query('types').where(-> @author == "escapes 's")

translate "/types?$filter=(title eq 'How%20to%20dial%20this%20%23%20%26%20such%20stuff%3F')",
    new Query('types').where(-> @title == "How to dial this # & such stuff?")

translate "/types?$filter=(author eq 'a''b''c')",
    new Query('types').where(author: "a'b'c")

translate "/types?$filter=(author eq 'a''b''c')",
    new Query('types').where(-> @author == "a'b'c")

translate "/types?$filter=(author eq 'a''b''c')",
    new Query('types').where(author: "a'b'c")

translate "/types?$filter=(author eq 'a''b''c')",
    new Query('types').where(-> @author == "a'b'c")

translate "/types?$filter=(author eq '''''''')",
    new Query('types').where(author: "'''")

translate "/types?$filter=(author eq '''''''')",
    new Query('types').where(-> @author == "'''")

translate "/types?$filter=(author eq 'escapes%20%22s')",
    new Query('types').where(author: 'escapes "s')

translate "/types?$filter=(author eq 'escapes%20%22s')",
    new Query('types').where(-> @author == 'escapes "s')

translate "/types?$filter=(published eq datetime'2011-11-21T05:16:21.010Z')",
    new Query('types').where(-> @published == new Date(Date.UTC 2011, 10, 21, 5, 16, 21, 10))

translate "/filtering?$filter=(price ge 12)",
    new Query('filtering').where(-> @price >= 12)

translate "/filtering?$filter=(price gt 12)",
    new Query('filtering').where(-> @price > 12)

translate "/filtering?$filter=(price le 12)",
    new Query('filtering').where(-> @price <= 12)

translate "/filtering?$filter=(price lt 12)",
    new Query('filtering').where(-> @price < 12)

translate "/filtering?$filter=(price ne 12)",
    new Query('filtering').where(-> @price != 12)

translate "/filtering?$filter=(author ne 'John')",
    new Query('filtering').where(-> @author != 'John')

translate "/filtering?$filter=(inStock ne true)",
    new Query('filtering').where(-> @inStock != true)

translate "/filtering?$filter=((price add 2) gt 30)",
    new Query('filtering').where(-> @price + 2 > 30)

translate "/filtering?$filter=((price sub 2) gt 30)",
    new Query('filtering').where(-> @price - 2 > 30)

translate "/filtering?$filter=((price mul 2) gt 30)",
    new Query('filtering').where(-> @price * 2 > 30)

translate "/filtering?$filter=((price div 2) gt 30)",
    new Query('filtering').where(-> @price / 2 > 30)

translate "/filtering?$filter=((price mod 2) gt 30)",
    new Query('filtering').where(-> @price % 2 > 30)

translate "/filtering?$filter=(((price add 1) mul 2) gt 30)",
    new Query('filtering').where(-> (@price + 1) * 2 > 30)

translate "/filtering?$filter=((price gt 10) and (price lt 20))",
    new Query('filtering').where(-> @price > 10 && @price < 20)

translate "/filtering?$filter=((price lt 20) and (price gt 10))",
    new Query('filtering').where(-> @price < 20 && @price > 10)

translate "/filtering?$filter=((price lt 20) and (author eq 'john'))",
    new Query('filtering').where(-> @price < 20 && @author == 'john')

translate "/filtering?$filter=((price eq 20) or (author eq 'john'))",
    new Query('filtering').where(-> @price == 20 || @author == 'john')

translate "/filtering?$filter=((inStock eq true) and ((price eq 20) or (author eq 'john')))",
    new Query('filtering').where(-> @inStock == true && (@price == 20 || @author == 'john'))

translate "/filtering?$filter=(((inStock eq true) or (price eq 10)) and ((price eq 20) or (author eq 'john')))",
    new Query('filtering').where(-> (@inStock == true || @price == 10) && (@price == 20 || @author == 'john'))

translate "/filtering?$filter=not (price gt 10)",
    new Query('filtering').where(-> !(@price > 10))

translate "/filtering?$filter=not (((price eq 20) or (author eq 'john')) and ((inStock eq true) or (price eq 10)))",
    new Query('filtering').where(-> !((@price == 20 || @author == 'john') && (@inStock == true || @price == 10)))

translate "/filtering?$filter=(not (price lt 5) or (((price eq 20) or (author eq 'john')) and ((inStock eq true) or (price eq 10))))",
    new Query('filtering').where(-> !(@price < 5) || ((@price == 20 || @author == 'john') && (@inStock == true || @price == 10)))

translate "/filtering?$filter=(price eq 10)",
    new Query('filtering').where(((a) -> @price == a), 10)

translate "/filtering?$filter=(price eq 11)",
    new Query('filtering').where(((a) -> @price == (a + 1)), 10)

###
# Note: CoffeeScript enhances the standard JavaScript in operator and ends up
# writing out code that results in more than a single expression so we've had
# to escape all of our in tests to regular JavaScript functions.
###
translate "/filtering?$filter=(((id eq 1) or (id eq 2)) or (id eq 3))",
    new Query('filtering').where(`function() { return this.id in [1, 2, 3]; }`)

translate "/filtering?$filter=(((id eq 1) or (id eq 2)) or (id eq 3))",
    new Query('filtering').where(`function(friends) { return this.id in friends; }`, [1, 2, 3])

translate "/filtering?$filter=((((id eq 1) or (id eq 2)) or (id eq 3)) or (id eq 0))",
    new Query('filtering').where(`function() { return this.id in [1, 2, 3] || this.id == 0; }`)

translate "/filtering?$filter=(true eq false)",
    new Query('filtering').where(`function() { return this.id in []; }`)

translate "/filtering?$filter=(((id eq 1) or (id eq 2)) or (id eq 3))",
    new Query('filtering').where(`function() { return this.id in [{a: 1}, {b: 2}, {other: 3}]; }`)

translate "/filtering?$filter=((((id eq 1) or (id eq 2)) or (id eq 3)) or (name eq 'admin'))",
    new Query('filtering').where(`function(others) { return this.id in others || this.name == 'admin'; }`, [{id: 1}, {id: 2}, {id: 3}])

translate "/filtering?$filter=(floor(price) eq 5)",
    new Query('filtering').where(-> Math.floor(@price) == Math.floor(5.5))

translate "/filtering?$filter=(ceiling(price) eq 6)",
    new Query('filtering').where(-> Math.ceil(@price) == Math.ceil(5.5))

translate "/filtering?$filter=(round(price) eq 6)",
    new Query('filtering').where(-> Math.round(@price) == Math.round(5.5))

translate "/filtering?$filter=(length(name) eq 3)",
    new Query('filtering').where(-> @name.length == 3)

translate "/filtering?$filter=(toupper(state) eq 'WA')",
    new Query('filtering').where(-> @state.toUpperCase() == 'WA')

translate "/filtering?$filter=(tolower(state) eq 'wa')",
    new Query('filtering').where(-> @state.toLowerCase() == 'wa')

translate "/filtering?$filter=(trim(state) eq 'wa')",
    new Query('filtering').where(-> @state.trim() == 'wa')

translate "/filtering?$filter=(indexof(state,'w') eq 0)",
    new Query('filtering').where(-> @state.indexOf('w') == 0)

translate "/filtering?$filter=((year(birthday) sub 1900) eq 100)",
    new Query('filtering').where(-> @birthday.getYear() == 100)

translate "/filtering?$filter=(year(birthday) eq 2000)",
    new Query('filtering').where(-> @birthday.getFullYear() == 2000)

translate "/filtering?$filter=(year(birthday) eq 2000)",
    new Query('filtering').where(-> @birthday.getUTCFullYear() == 2000)

translate "/filtering?$filter=((month(birthday) sub 1) eq 10)",
    new Query('filtering').where(-> @birthday.getMonth() == 10)

translate "/filtering?$filter=((month(birthday) sub 1) eq 10)",
    new Query('filtering').where(-> @birthday.getUTCMonth() == 10)

translate "/filtering?$filter=(day(birthday) eq 21)",
    new Query('filtering').where(-> @birthday.getDate() == 21)

translate "/filtering?$filter=(day(birthday) eq 21)",
    new Query('filtering').where(-> @birthday.getUTCDate() == 21)

translate "/filtering?$filter=(concat(name,'x') eq 'x')",
    new Query('filtering').where(-> @name.concat('x') == 'x')

translate "/filtering?$filter=(replace(name,'x','y') eq 'y')",
    new Query('filtering').where(-> @name.replace('x','y') == 'y')

translate "/filtering?$filter=(substring(name,0,1) eq 'x')",
    new Query('filtering').where(-> @name.substring(0,1) == 'x')

translate "/filtering?$filter=(substring(name,0,1) eq 'x')",
    new Query('filtering').where(-> @name.substr(0,1) == 'x')

translate "/ordering?$orderby=price",
    new Query('ordering').orderBy('price')

translate "/ordering?$orderby=price desc",
    new Query('ordering').orderByDescending('price')

translate "/ordering?$orderby=price,rank desc",
    new Query('ordering').orderBy('price').orderByDescending('rank')

translate "/selection?$select=price",
    new Query('selection').select('price')

translate "/selection?$select=price,inStock",
    new Query('selection').select('price', 'inStock')

translate "/paging?$skip=10",
    new Query('paging').skip(10)

translate "/paging?$top=10",
    new Query('paging').take(10)

translate "/paging?$top=0",
    new Query('paging').take(0)

translate "/paging?$skip=10&$top=20",
    new Query('paging').skip(10).take(20)

translate "/combine?$filter=(price eq 10)&$orderby=title&$skip=10&$top=20&$select=price,title&$inlinecount=allpages",
    new Query('combine')
        .where(-> @price == 10)
        .orderBy('title')
        .select('price', 'title')
        .skip(10)
        .take(20)
        .includeTotalCount()

translate "/literal?$filter=(id eq 12)",
    new Query('literal').where("id eq 12")

translate "/literal?$filter=(id eq 13)",
    new Query('literal').where("id eq ?", 13)

translate "/literal?$filter=(author eq 'john')",
    new Query('literal').where("author eq ?", 'john')

translate "/literal?$filter=((title eq '?') and (price eq 5))",
    new Query('literal').where("(title eq '?') and (price eq ?)", 5)

translate "/literal?$filter=((true or true) and (id eq 1))",
    new Query('literal').where("true or true").where("id eq 1")

translate "/literal?$filter=('john')",
    new Query('literal').where("?", 'john')

translate "/literal?$filter=('?)",
    new Query('literal').where("'?")

translate "/literal",
    new Query('literal').where("")

translate "/literal?$filter= ",
    new Query('literal').where(" ")

translate "/literal?$filter=('(test' eq 'test)')",
    new Query('literal').where("'(test' eq 'test)'")

translate "/count?$inlinecount=allpages",
    new Query('count').includeTotalCount()

translate "/deleted?__includeDeleted=true",
    new Query('deleted').includeDeleted()

test 'toOData literals', ->
    q = new Query('literal').where("1 eq 1 ) or ( 1 eq 1")
    assert.throws (-> q.toOData()), /Unbalanced parentheses/

    q = new Query('literal').where("(1 eq 1) ) or ( (1 eq 1)")
    assert.throws (-> q.toOData()), /Unbalanced parentheses/

    q = new Query('literal').where("(")
    assert.throws (-> q.toOData()), /Unbalanced parentheses/

    q = new Query('literal').where(")")
    assert.throws (-> q.toOData()), /Unbalanced parentheses/

    q = new Query('literal').where(")()(")
    assert.throws (-> q.toOData()), /Unbalanced parentheses/

    q = new Query('literal').where("(()")
    assert.throws (-> q.toOData()), /Unbalanced parentheses/

    q = new Query('literal').where("())")
    assert.throws (-> q.toOData()), /Unbalanced parentheses/

test 'fromOData', ->
    q = Query.Providers.OData.fromOData 'table', null, null, null, null, null, false
    assert.equal q.getComponents().table, 'table'

    q = Query.Providers.OData.fromOData 'checkins', 'id eq 12', undefined, undefined, 10, null, false, true
    assert.equal q.getComponents().filters.type, 'LiteralExpression'
    assert.equal q.getComponents().take, 10
    assert.equal q.getComponents().includeTotalCount, false
    assert.equal q.getComponents().includeDeleted, true

    q = Query.Providers.OData.fromOData 'checkins', 'id eq 12', 'name,price, state asc   ,  count desc', 5, 10, 'a,   b , c', true
    assert.equal q.getComponents().filters.type, 'LiteralExpression'
    assert.equal q.getComponents().ordering.name, true
    assert.equal q.getComponents().ordering.price, true
    assert.equal q.getComponents().ordering.state, true
    assert.equal q.getComponents().ordering.count, false
    assert.equal q.getComponents().orderClauses.length, 4
    assert.equal q.getComponents().orderClauses[0].name, 'name'
    assert.equal q.getComponents().orderClauses[0].ascending, true
    assert.equal q.getComponents().orderClauses[1].name, 'price'
    assert.equal q.getComponents().orderClauses[1].ascending, true
    assert.equal q.getComponents().orderClauses[2].name, 'state'
    assert.equal q.getComponents().orderClauses[2].ascending, true
    assert.equal q.getComponents().orderClauses[3].name, 'count'
    assert.equal q.getComponents().orderClauses[3].ascending, false
    assert.equal q.getComponents().skip, 5
    assert.equal q.getComponents().take, 10
    assert.equal q.getComponents().selections[0], 'a'
    assert.equal q.getComponents().selections[1], 'b'
    assert.equal q.getComponents().selections[2], 'c'
    assert.equal q.getComponents().includeTotalCount, true
