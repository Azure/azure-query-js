###
# ----------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# ----------------------------------------------------------------------------
###

classOf = (obj) -> 
  Object::toString.call(obj).slice(8, -1).toLowerCase()

# Array.prototype.reduce shim for IE8 based on https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Array/Reduce
if not Array.prototype.reduce?
  Array.prototype.reduce = (accumulator, moreArgs...) ->
    array = this
    arrayLength = array.length
    currentIndex = 0
    currentValue = undefined

    if not array?
      throw new TypeError("Object is null or undefined")
    if typeof accumulator != "function"
      throw new TypeError("First argument is not callable")

    if moreArgs.length == 0
      if arrayLength == 0
        throw new TypeError("Array length is 0 and no second argument")
      else
        # Start accumulating at the second element
        currentValue = array[0]
        currentIndex = 1
    else
      currentValue = moreArgs[0]

    while currentIndex < arrayLength
      if currentIndex of array
        currentValue = accumulator.call undefined, currentValue, array[currentIndex], array
      ++currentIndex

    return currentValue

# Array.prototype.map shim for IE8 based on https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Array/Map
if not Array.prototype.map?
  Array.prototype.map = (callback, thisArg) ->
    if not this?
      throw new TypeError("this is null or not defined")
    if typeof callback != "function"
      throw new TypeError(callback + " is not a function")

    thisArg = if thisArg then thisArg else undefined
    inputArray = Object(this)
    len = inputArray.length >>> 0
    outputArray = new Array(len)

    for elem, index in inputArray when index of inputArray
      outputArray[index] = callback.call thisArg, elem, index, inputArray

    return outputArray

# Array.isArray shim for IE8 based on https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Array/IsArray
if not Array.isArray?
  Array.isArray = (vArg) ->
    return Object.prototype.toString.call(vArg) == "[object Array]"


exports.isObject = (obj) ->
  Object::toString.call(obj).slice(8, -1).toLowerCase() == 'object'

exports.isString = (obj) ->
  typeof obj == 'string'

exports.isFunction = (obj) ->
  typeof obj == 'function'

exports.isArray = Array.isArray

exports.isNumber = (obj) ->
  typeof obj == 'number'

exports.isBoolean = (obj) ->
  typeof obj == 'boolean'

exports.isDate = (obj) ->
  classOf(obj) == 'date'

exports.functionName = (fn) ->
  # For IE8 compatibility, this is now a regular function instead of a property
  if typeof Function.prototype.name == 'function'
    Function.prototype.name.call fn
  else
    source = fn.toString()
    prefix = 'function '
    if (source[0..prefix.length - 1] == prefix)
        index = source.indexOf '(', prefix.length
        if index > prefix.length
            return source[prefix.length..index - 1]
    null