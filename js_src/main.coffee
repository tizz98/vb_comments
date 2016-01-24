(($, C, moment, _) ->
  C.constant =
    DIVIDER_CHARACTER: "-"
    DICTIONARY_DIVIDER: "-"
    COMMENT_CHARACTER: "\'"
    EMPTY_DICT_STRING: "(None)"
    DIVIDER_LENGTH: 60
    SUB_HEADER: 0
    FUNC_HEADER: 1

  C.constant.MAX_TEXT_LENGTH = C.constant.DIVIDER_LENGTH - 4
  C.constant.DIVIDER_TEXT = Array(C.constant.DIVIDER_LENGTH + 1).join C.constant.DIVIDER_CHARACTER
  C.constant.DIVIDER_LINE = C.constant.COMMENT_CHARACTER + C.constant.DIVIDER_TEXT + "\n"

  C.$ =
    output: $ "#output"
    name: $ "#name"
    assignment: $ '#assignment'
    input_radio_ctype: $ 'input[type=radio][name=ctype]'
    objNameSpan: $ '.obj-name-txt'
    headerInput: $ '#header-input'
    globalContainer: $ '#global-var-container'
    localContainer: $ '#local-var-container'
    parameterContainer: $ '#parameter-container'
    returnContainer: $ '#return-container'
    subDesc: $ '#sub-desc'
    funcDesc: $ '#func-desc'
    objData: $ '#obj-data'
    programPurposeContainer: $ '#program-purpose-container'
    programPurpose: $ '#program-purpose'
    extraPurposeTxt: $ '#extra-purpose-txt'
    parameters: $ '#parameters'
    globals: $ '#globals'
    locals: $ '#locals'
    headerData: $ '#header-data'
    returnId: $ '#return'
    purpose: $ '#purpose'
    objName: $ '#obj-name'
    addGlobal: $ '#add-global'
    addLocal: $ '#add-local'

  C.classes =
    VbComment: ->
      self = @

      self.name = ""
      self.writtenOn = moment().format("MM/DD/YYYY")
      self.objectName = ""
      self._assignment = ""
      self.assignment = ""
      self.commentType = ""
      self.purpose = ""
      self.program_purpose = ""
      self.global_vars = []
      self.local_vars = []
      self.returns = new C.classes.ReturnType()
      self.parameters = []

      self.reinitialize = ->
        self.writtenOn = moment().format("MM/DD/YYYY")
        self.objectName = ""
        self.commentType = ""
        self.purpose = ""
        self.global_vars = []
        self.local_vars = []
        self.returns = new C.classes.ReturnType()
        self.parameters = []
        self.program_purpose = ""
        return

      self.getSortedGlobals = ->
        _.sortBy self.global_vars, (obj) ->
          obj.name

      self.getSortedLocals = ->
        _.sortBy self.local_vars, (obj) ->
          obj.name

      self.getObjStr = ->
        if self.commentType == "file" or self.commentType == "main"
          "File"
        else if self.commentType == "sub"
          "Subprogram"
        else if self.commentType == "func"
          "Function"

      self.setAssignment = (val) ->
        self._assignment = val

        if $.isNumeric val
          self.assignment = "Assign" + val
        else
          self.assignment = val

        return

      self.setPurpose = (val) ->
        self.purpose = val.replace /(\r\n|\n|\r)/gm, ""
        return

      self.setProgramPurpose = (val) ->
        self.program_purpose = val.replace /(\r\n|\n|\r)/gm, ""
        return

      self.getUrlKwargs = ->
        "?name=#{self.name}&assignment=#{self._assignment}"

      self.updateUrl = ->
        if history.pushState
          newUrl = "#{window.location.protocol}//#{window.location.host}#{window.location.pathname}#{self.getUrlKwargs()}"
          history.pushState(path: newUrl, '', newUrl)

        return

      self.getString = ->
        commentString = C.constant.DIVIDER_LINE

        if self.commentType == 'file' or self.commentType == 'main'
          commentString += C.utils.splitText "File Name: #{self.objectName}", C.utils.padCenter
          commentString += C.utils.splitText "Part of Project: #{self.assignment}", C.utils.padCenter
          commentString += C.constant.DIVIDER_LINE
        else if self.commentType == 'sub' or self.commentType == 'func'
          commentString += C.utils.splitText "#{self.getObjStr()} Name: #{self.objectName}", C.utils.padCenter
          commentString += C.constant.DIVIDER_LINE

        # Written by part (all have this)
        commentString += C.utils.splitText "Written By: #{self.name}", C.utils.padCenter
        commentString += C.utils.splitText "Written On: #{self.writtenOn}", C.utils.padCenter
        commentString += C.utils.DIVIDER_LINE

        # Purpose
        commentString += C.utils.splitText "#{self.getObjStr()} Purpose:"
        commentString += C.utils.splitText ""
        commentString += C.utils.splitText self.purpose
        commentString += C.constant.DIVIDER_LINE

        if self.commentType == 'main'
          commentString += C.utils.splitText 'Program Purpose:'
          commentString += C.utils.splitText ''
          commentString += C.utils.splitText self.purpose
          commentString += C.constant.DIVIDER_LINE

          globals = self.getSortedGlobals()
          commentString += C.utils.splitText "Global Variable Dictionary (alphabetically):"

          if globals.length > 0
            for global in globals
              commentString += C.utils.splitText global.getString(), C.utils.padRight, true, (global.name + " - ").length
          else
            commentString += C.utils.splitText C.constant.EMPTY_DICT_STRING

          commentString += C.constant.DIVIDER_LINE
        else if self.commentType == 'sub' or self.commentType == 'func'
          commentString += C.utils.splitText 'Parameter Dictionary (in parameter order):'

          if self.parameters.length > 0
            for param in self.parameters
              commentString += C.utils.splitText param.getString(), C.utils.padRight, true, (param.name + " - ").length
          else
            commentString += C.utils.splitText C.constant.EMPTY_DICT_STRING

          commentString += C.constant.DIVIDER_LINE

          if self.commentType == 'func'
            commentString += C.utils.splitText "Returns:"
            commentString += C.utils.splitText self.returns.getString(), C.utils.padRight, true, (self.returns.dataType + ' - ').length
            commentString += C.constant.DIVIDER_LINE

        commentString
      return

    Variable: (name="", description='', id='', var_arr='') ->
      self = @

      self.name = name
      self.description = description
      self.id = id
      self.var_arr = var_arr

      self.getString = ->
        "#{self.name} #{C.constant.DICTIONARY_DIVIDER} #{self.description}"

      self.addDescriptionListener = ->
        $input = $($("##{self.id}").find('input')[0])
        $input.keyup ->
          self.description = $input.val()
          C.utils.updateOutput comment
          return
        return

      self.addDeleteListener = ->
        $($("##{self.id}").find("button")[0]).on("click", ->
          comment[self.var_arr] = comment[self.var_arr].filter( (obj)  ->
            obj.id != self.id
          )

          $("##{self.id}").remove()
          C.utils.updateOutput comment
        )
        return
      return

    ReturnType: (dataType='', description='') ->
      self.dataType = dataType
      self.description = description

      self.getString = ->
        "#{self.dataType} #{C.constant.DICTIONARY_DIVIDER} #{self.description}"

      return

  C.misc =
    queryString: do ->
        query = window.location.search.substring 1
        vars = query.split "&"
        query_string = {}

        for variable in vars
          pair = variable.split "="

          if not query_string[pair[0]]?
            query_string[pair[0]] = decodeURIComponent pair[1]
          else if typeof query_string[pair[0]] is "string"
            arr = [query_string[pair[0]], decodeURIComponent(pair[1])]
            query_string[pair[0]] = arr
          else
            query_string[pair[0]].push decodeURIComponent(pair[1])

        query_string

  C.utils =
    padRight: (stringToPad, maxLength=C.constant.MAX_TEXT_LENGTH, charToPadWith=" ") ->
      emptySpace = maxLength - stringToPad.length
      padding = Array(emptySpace + 1).join charToPadWith

      stringToPad + padding

    padCenter: (stringToPad, maxLength=C.constant.MAX_TEXT_LENGTH, charToPadWith=" ") ->
      emptySpace = maxLength - stringToPad.length
      spaceDiv2 = emptySpace / 2

      if spaceDiv2 == Number(spaceDiv2) && spaceDiv2 % 1 != 0
        paddingLeft = Math.floor spaceDiv2
        paddingRight = Math.ceil spaceDiv2
      else
        paddingLeft = paddingRight = spaceDiv2

      Array(paddingLeft + 1).join(charToPadWith) + stringToPad + Array(paddingRight + 1).join charToPadWith

    getCommentLine: (text, paddingFunction=C.utils.padRight) ->
      C.constant.COMMENT_CHARACTER + C.constant.DIVIDER_CHARACTER + " " + paddingFunction(text, C.constant.MAX_TEXT_LENGTH, " ") + " " + C.constant.DIVIDER_CHARACTER + "\n"

    splitText: (text, paddingFunction=C.utils.padRight, indentSuccessiveLines=false, indentLen=5) ->
      maxLength = C.constant.MAX_TEXT_LENGTH

      if text.length > maxLength
        words = text.split " "
        tempLine = returnText = ""

        for word, idx in words
          textToAdd = " " + word
          firstWord = tempLine.length == 0
          firstLine = idx == 0

          if not firstWord and (tempLine.length + textToAdd.length) > maxLength
            returnText += C.utils.getCommentLine tempLine, paddingFunction
            tempLine = ""

            if indentSuccessiveLines and not firstLine
              tempLine += Array(indentLen + 1).join " "

            tempLine += word
          else if firstWord
            if indentSuccessiveLines and not firstLine
              tempLine += Array(indentLen + 1).join " "
            tempLine += word
          else
            tempLine += textToAdd
      else
        returnText = C.utils.getCommentLine text, paddingFunction

      returnText

    updateOutput: (comment) ->
      C.$.output.val comment.getString()
      return

    removeElementFromArray: (array) ->
      a = arguments
      L = array.length

      while L > 1 and array.length
        what = a[--L]
        while (ax = array.indexOf(what)) != -1
          array.splice ax, 1

      array

    parseHeaderParameters: (parameterString) ->
      paramStrings = C.utils.removeElementFromArray parameterString.split(", "), ""
      params_to_return = []

      for param in paramStrings
        paramSplit = param.split " As "
        paramName = paramSplit[0]

        params_to_return.push new C.classes.Variable paramName

      params_to_return

    parseHeader: (header, headerType) ->
      getReturnType = headerType == C.constant.FUNC_HEADER
      initialHeaderSplit = header.split "("
      parameterString = initialHeaderSplit[1].split(")")[0]
      headerName = initialHeaderSplit[0].split(" ")[1]
      returnType = if getReturnType then header.split(" As ").pop() else null
      parameters = C.utils.parseHeaderParameters parameterString

      # Return
      name: headerName
      type: returnType
      parameters: parameters

    parseSubHeader: (header) ->
      C.utils.parseHeader header, C.constant.SUB_HEADER

    parseFuncHeader: (header) ->
      C.utils.parseHeader header, C.constant.FUNC_HEADER

    randomString: (length=16) ->
      chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
      result = ""

      for z in [length..0]
        result += chars[Math.floor(Math.random() * chars.length)]

      result

  comment = new C.classes.VbComment()

  if C.misc.queryString.name?
    comment.name = C.misc.queryString.name
    C.$.name.val comment.name

  if C.misc.queryString.assignment?
    comment.setAssignment C.misc.queryString.assignment
    C.$.assignment.val C.misc.queryString.assignment

  C.$.input_radio_ctype.change( ->
    comment.reinitialize()
    comment.commentType = @value

    if @value == 'file' or @value == 'main'
      C.$.objNameSpan.html 'File'
      C.$.headerInput.hide()
      C.$.returnContainer.hide()

      if @value == 'file'
        C.$.globalContainer.hide()
        C.$.programPurposeContainer.hide()
        C.$.extraPurposeTxt.html ""
      else
        C.$.programPurposeContainer.show()
        C.$.globalContainer.show()
        C.$.extraPurposeTxt.html "File "
    else if @value == 'sub'
      C.$.objNameSpan.html "Subprogram"
      C.$.headerInput.show()
      C.$.globalContainer.hide()
      C.$.returnContainer.hide()
      C.$.subDesc.show()
      C.$.funcDesc.hide()
    else if @value == 'func'
      C.$.objNameSpan.html "Function"
      C.$.headerInput.show()
      C.$.globalContainer.hide()
      C.$.subDesc.hide()
      C.$.funcDesc.show()

    if @value == 'sub' or @value == 'func'
      C.$.objData.hide()
      C.$.localContainer.show()
      C.$.programPurposeContainer.hide()
      C.$.extraPurposeTxt.html ""
    else
      C.$.objData.show()
      C.$.parameterContainer.hide()
      C.$.localContainer.hide()

    C.$.parameters.find('tr').remove()
    C.$.globals.find('tr').remove()
    C.$.locals.find('tr').remove()
    C.$.headerData.val ""
    C.$.returnId.val ""
    C.$.purpose.val ""
    C.$.objName.val ""
    C.$.programPurpose.val ""

    C.utils.updateOutput comment
    return
  )

  C.$.name.keyup( ->
    comment.name = C.$.name.val()
    C.utils.updateOutput comment
    comment.updateUrl()
    return
  )

  C.$.assignment.keyup( ->
    comment.setAssignment C.$.assignment.val()
    C.utils.updateOutput comment
    comment.updateUrl()
    return
  )

  C.$.objName.keyup( ->
    comment.objectName = C.$.objName.val()
    C.utils.updateOutput comment
    return
  )

  C.$.purpose.keyup( ->
    comment.setPurpose C.$.purpose.val()
    C.utils.updateOutput comment
    return
  )

  C.$.headerData.keyup( ->
    try
      parseFunc = if comment.commentType == 'sub' then C.utils.parseSubHeader else C.utils.parseFuncHeader
      headerDict = parseFunc C.$.headerData.val()
      table = document.getElementById 'parameters'

      C.$.parameters.find('tr').remove()

      comment.parameters = headerDict.parameters
      comment.returns = new C.classes.ReturnType headerDict.type
      comment.objectName = headerDict.name

      C.$.headerData.css "color", "black"

      for param in comment.parameters
        param.id = C.utils.randomString()

        row = table.insertRow -1
        nameCol = row.insertCell 0
        descCol = row.insertCell 1

        $(row).attr 'id', param.id

        nameCol.innerHTML = param.name
        descCol = '<input type="text" class="parameter-desc">'
        param.addDescriptionListener()

      C.$.parameterContainer.show()

      if comment.commentType == 'func'
        C.$.returnContainer.show()
    catch
      comment.parameters = []

      C.$.headerData.css "color", "red"
      C.$.parameterContainer.hide()
      C.$.returnContainer.hide()
    finally
      C.utils.updateOutput comment

    return
  )

  C.$.addGlobal.on('click', ->
    globalName = prompt 'What is the name of the global variable?'
    globalDesc = prompt 'Please describe the global variable:'
    globalId = C.utils.randomString()
    global = new C.classes.Variable globalName, globalDesc, globalId, 'global_vars'
    table = document.getElementById 'globals'

    row = table.insertRow -1
    nameCol = row.insertCell 0
    descCol = row.insertCell 1
    deleteBtnCol = row.insertCell 2

    comment.global_vars.push global

    nameCol.innerHTML = global.name
    descCol.innerHTML = global.description
    deleteBtnCol.outerHTML = '<button class="btn btn-danger-outline"><i class="fa fa-trash-o"></i></button>'

    $(row).attr 'id', globalId
    global.addDeleteListener()

    C.utils.updateOutput comment
    return
  )

  C.$.addLocal.on('click', ->
    localName = prompt 'What is the name of the local variable?'
    localDesc = prompt 'Please describe the local variable:'
    localId = C.utils.randomString()
    local = new C.classes.Variable(localName, localDesc, localId, 'local_vars')
    table = document.getElementById 'locals'

    row = table.insertRow -1
    nameCol = row.insertCell 0
    descCol = row.insertCell 1
    deleteBtnCol = row.insertCell 2

    comment.local_vars.push local

    nameCol.innerHTML = local.name
    descCol.innerHTML = local.description
    deleteBtnCol.outerHTML = '<button class="btn btn-danger-outline"><i class="fa fa-trash-o"></i></button>'

    $(row).attr 'id', localId
    local.addDeleteListener()

    C.utils.updateOutput comment
    return
  )

  C.$.returnId.keyup( ->
    comment.returns.description = C.$.returnId.val()
    C.utils.updateOutput comment
    return
  )

  C.$.programPurpose.keyup( ->
    comment.setProgramPurpose C.$.programPurpose.val()
    C.utils.updateOutput comment
    return
  )

  C.utils.updateOutput comment

)(jQuery, VbComment, moment, _)
