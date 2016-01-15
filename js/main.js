(function($, C, moment, _){
    /*
        Get the url query string
     */
     var QueryString = function () {
      // This function is anonymous, is executed immediately and
      // the return value is assigned to QueryString!
      var query_string = {};
      var query = window.location.search.substring(1);
      var vars = query.split("&");
      for (var i=0;i<vars.length;i++) {
        var pair = vars[i].split("=");
            // If first entry with this name
        if (typeof query_string[pair[0]] === "undefined") {
          query_string[pair[0]] = decodeURIComponent(pair[1]);
            // If second entry with this name
        } else if (typeof query_string[pair[0]] === "string") {
          var arr = [ query_string[pair[0]],decodeURIComponent(pair[1]) ];
          query_string[pair[0]] = arr;
            // If third or later entry with this name
        } else {
          query_string[pair[0]].push(decodeURIComponent(pair[1]));
        }
      }
        return query_string;
    }();

    /*
        Comment CONSTANTS
     */
    C.const = {};
    C.const.DIVIDER_CHARACTER = "-";
    C.const.DICTIONARY_DIVIDER = "-";
    C.const.COMMENT_CHARACTER = "\'";
    C.const.EMPTY_DICT_STRING = "(None)";
    C.const.DIVIDER_LENGTH = 60;
    C.const.SUB_HEADER = 0;
    C.const.FUNC_HEADER = 1;
    C.const.MAX_TEXT_LENGTH = C.const.DIVIDER_LENGTH - 4;
    C.const.DIVIDER_TEXT  = Array(C.const.DIVIDER_LENGTH+1).join(C.const.DIVIDER_CHARACTER);
    C.const.DIVIDER_LINE = C.const.COMMENT_CHARACTER + C.const.DIVIDER_TEXT + "\n";

    /*
        Comment Utility Functions
     */
    C.utils = {};
    C.utils.padRight = function(stringToPad, maxLength, charToPadWith) {
        var emptySpace = maxLength - stringToPad.length,  // JS arrays are weird...
            padding = Array(emptySpace + 1).join(charToPadWith);
        return stringToPad + padding;
    };
    C.utils.padCenter = function(stringToPad, maxLength, charToPadWith) {
        var emptySpace = maxLength - stringToPad.length, // JS arrays are weird...
            spaceDiv2 = emptySpace / 2,
            paddingLeft,
            paddingRight;

        if (spaceDiv2 === Number(spaceDiv2) && spaceDiv2 % 1 !== 0) {
            paddingLeft = Math.floor(spaceDiv2);
            paddingRight = Math.ceil(spaceDiv2);
        } else {
            paddingLeft = paddingRight = spaceDiv2;
        }

        return Array(paddingLeft + 1).join(charToPadWith) + stringToPad + Array(paddingRight + 1).join(charToPadWith);
    };

    C.utils.getCommentLine = function(text, paddingFunction) {
        if (paddingFunction === undefined) {
            paddingFunction = C.utils.padRight;
        }
        return C.const.COMMENT_CHARACTER + C.const.DIVIDER_CHARACTER + " " + paddingFunction(text, C.const.MAX_TEXT_LENGTH, " ") + " " + C.const.DIVIDER_CHARACTER + "\n";
    };

    C.utils.splitText = function(text, paddingFunction, indentSuccessiveLines, indentLen) {
        var maxLength = C.const.MAX_TEXT_LENGTH,
            returnText;
        indentSuccessiveLines = indentSuccessiveLines || false;
        indentLen = indentLen || 5;

        if (text.length > maxLength) {
            var words = text.split(" "),
                tempLine = "";
            returnText = "";

            for (var i = 0; i < words.length; ++i) {
                var word = words[i],
                    textToAdd = " " + word,
                    firstWord = tempLine.length == 0,
                    firstLine = i == 0;
                if (!firstWord && (tempLine.length + textToAdd.length) > maxLength) {
                    returnText += C.utils.getCommentLine(tempLine, paddingFunction);
                    tempLine = "";

                    if (indentSuccessiveLines && !firstLine) {
                        tempLine += Array(indentLen + 1).join(" ");
                    }
                    tempLine += word;
                } else if (firstWord) {
                    if (indentSuccessiveLines && !firstLine) {
                        tempLine += Array(indentLen + 1).join(" ");
                    }
                    tempLine += word;
                } else {
                    tempLine += textToAdd;
                }
            }

            // Leftover text...
            if (tempLine.length > 0)
                returnText += C.utils.getCommentLine(tempLine, paddingFunction);
        } else {
            returnText = C.utils.getCommentLine(text, paddingFunction);
        }

        return returnText;
    };

    C.utils.updateOutput = function(comment) {
        $("#output").val(comment.getString());
    };

    C.utils.parseParameters = function(parameterString) {
        var paramStrings = parameterString.split(", "),
            params_to_return = [];

        for (var i = 0; i < paramStrings.length; ++i) {
            var param = paramStrings[i],
                paramSplit = param.split(" As "),
                paramName = paramSplit[0];
            params_to_return.push(new C.classes.Variable(paramName));
        }

        return params_to_return;
    };

    C.utils.parseHeader = function(header, headerType) {
        var getReturnType = headerType === C.const.FUNC_HEADER,
            parameterString = header.split("(")[1].split(")")[0],
            returnType = getReturnType ? header.split(" As ").pop() : null,
            parameters = C.utils.parseParameters(parameterString);
        return {
            type: returnType,
            parameters: parameters
        };
    };

    C.utils.parseSubHeader = function(header) {
        return C.utils.parseHeader(header, C.const.SUB_HEADER);
    };

    C.utils.parseFuncHeader = function(header) {
        return C.utils.parseHeader(header, C.const.FUNC_HEADER);
    };

    C.utils.randomString = function(length) {
        var result = '',
            chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
        for (var i = length; i > 0; --i) result += chars[Math.floor(Math.random() * chars.length)];
        return result;
    };

    /*
        Comment Classes
     */
    C.classes = {};
    C.classes.VbComment = function() {
        var self = this;

        self.name = "";
        self.writtenOn = moment().format("MM/DD/YYYY");
        self.objectName = "";
        self.assignment = "";
        self.commentType = "";
        self.purpose = "";
        self.global_vars = [];
        self.local_vars = [];
        self.returns = new C.classes.ReturnType();
        self.parameters = [];

        self.getSortedGlobals = function() {
            return _.sortBy(self.global_vars, function(obj) {
                return obj.name;
            });
        };

        self.getSortedLocals = function() {
            return _.sortBy(self.local_vars, function(obj) {
                return obj.name;
            });
        };

        self.getObjStr = function() {
            var ret = "";

            if (self.commentType === "file" || self.commentType === "main") {
                ret = "File";
            } else if (self.commentType === "sub") {
                ret = "Subprogram";
            } else if (self.commentType === "func") {
                ret = "Function";
            }

            return ret;
        };

        self.setAssignment = function(val) {
            if ($.isNumeric(val)) {
                self.assignment = "Assign" + val;
            } else {
                self.assignment = val;
            }
        };

        self.setPurpose = function(val) {
            self.purpose = val.replace(/(\r\n|\n|\r)/gm, " ");
        };

        self.getString = function() {
            var commentString = C.const.DIVIDER_LINE;

            // Top part (different per type)
            if (self.commentType === "file" || self.commentType == "main") {
                commentString += C.utils.splitText("File Name : " + self.objectName, C.utils.padCenter);
                commentString += C.utils.splitText("Part of Project : " + self.assignment, C.utils.padCenter);
                commentString += C.const.DIVIDER_LINE;
            } else if (self.commentType === "sub" || self.commentType === "func") {
                var objStr = self.getObjStr();
                commentString += C.utils.splitText(objStr + " Name: " + self.objectName, C.utils.padCenter);
                commentString += C.const.DIVIDER_LINE;
            }

            // written by part (all have this)
            commentString += C.utils.splitText("Written By: " + self.name, C.utils.padCenter);
            commentString += C.utils.splitText("Written On: " + self.writtenOn, C.utils.padCenter);
            commentString += C.const.DIVIDER_LINE;

            commentString += C.utils.splitText(self.getObjStr() + " Purpose:");
            commentString += C.utils.splitText("");
            commentString += C.utils.splitText(self.purpose);
            commentString += C.const.DIVIDER_LINE;

            if (self.commentType === "main") {
                var globals = self.getSortedGlobals();
                commentString += C.utils.splitText("Global Variable Dictionary (alphabetically):");

                if (globals.length > 0) {
                    for (var i = 0; i < globals.length; ++i) {
                        commentString += C.utils.splitText(globals[i].getString(), C.utils.padRight, true, (globals[i].name + " - ").length);
                    }
                } else {
                    commentString += C.utils.splitText(C.const.EMPTY_DICT_STRING);
                }

                commentString += C.const.DIVIDER_LINE;
            } else if (self.commentType === "sub" || self.commentType === "func") {
                commentString += C.utils.splitText("Parameter Dictionary (in parameter order):");

                if (self.parameters.length > 0) {
                    for (var i = 0; i < self.parameters.length; ++i) {
                        commentString += C.utils.splitText(self.parameters[i].getString(), C.utils.padRight, true, (self.parameters[i].name + " - ").length);
                    }
                } else {
                    commentString += C.utils.splitText(C.const.EMPTY_DICT_STRING);
                }
                commentString += C.const.DIVIDER_LINE;

                commentString += C.utils.splitText("Local Variable Dictionary (alphabetically):");
                var locals = self.getSortedLocals();
                if (locals.length > 0) {
                    for (var i = 0; i < locals.length; ++i) {
                        commentString += C.utils.splitText(locals[i].getString(), C.utils.padRight, true, (locals[i].name + " - ").length);
                    }
                } else {
                    commentString += C.utils.splitText(C.const.EMPTY_DICT_STRING);
                }
                commentString += C.const.DIVIDER_LINE;

                if (self.commentType === "func") {
                    commentString += C.utils.splitText("Returns:");
                    commentString += C.utils.splitText(self.returns.getString(), C.utils.padRight, true, (self.returns.dataType + " - ").length);
                    commentString += C.const.DIVIDER_LINE;
                }
            }

            return commentString;
        };
    };

    C.classes.Variable = function(name, description, id, var_arr) {
        var self = this;

        self.name = name || "";
        self.description = description || "";
        self.id = id || "";  // table row id
        self.varr_arr = var_arr || "";

        self.getString = function() {
            return self.name + " " + C.const.DICTIONARY_DIVIDER + " " + self.description;
        };

        self.addDescriptionListener = function() {
            var $input = $($("#" + self.id).find("input")[0]);
            $input.keyup(function () {
                self.description = $input.val();
                C.utils.updateOutput(comment);
            });
        };

        self.addDeleteListener = function() {
            $($("#" + self.id).find("button")[0]).on("click", function() {
                comment[self.varr_arr] = comment[self.varr_arr].filter(function (obj) {
                    return obj.id !== self.id;
                });

                $("#" + self.id).remove();

                C.utils.updateOutput(comment);
            });
        }
    };

    C.classes.ReturnType = function(dataType, description) {
        var self = this;

        self.dataType = dataType || "";
        self.description = description || "";

        self.getString = function() {
            return self.dataType + " " + C.const.DICTIONARY_DIVIDER + " " + self.description;
        }
    };

    /*
        Additional logic goes here:
     */
    var comment = new C.classes.VbComment();

    if (QueryString.name !== undefined) {
        comment.name = QueryString.name;
        $("#name").val(comment.name);
    }

    if (QueryString.assignment !== undefined) {
        comment.setAssignment(QueryString.assignment);
        $("#assignment").val(QueryString.assignment);
    }

    /*
        jQuery event handlers
     */
    $("input[type=radio][name=ctype]").change(function(){
        // todo : reset all tables when changing so no data is left behind...
        var value = this.value,
            $objNameSpan = $(".obj-name-txt"),
            $headerInput = $("#header-input"),
            $globalContainer = $("#global-var-container"),
            $localContainer = $("#local-var-container"),
            $parameterContainer = $("#parameter-container"),
            $returnContainer = $("#return-container"),
            $subDesc = $("#sub-desc"),
            $funcDesc = $("#func-desc");
        comment.commentType = value;
        C.utils.updateOutput(comment);

        if (value === "file" || value === "main") {
            $objNameSpan.html("File");
            $headerInput.hide();
            $returnContainer.hide();

            if (value == "file") {
                $globalContainer.hide();
            } else {
                $globalContainer.show();
            }
        } else if (value === "sub") {
            $objNameSpan.html("Subprogram");
            $headerInput.show();
            $globalContainer.hide();
            $returnContainer.hide();
            $subDesc.show();
            $funcDesc.hide();
        } else if (value === "func") {
            $objNameSpan.html("Function");
            $headerInput.show();
            $globalContainer.hide();
            $subDesc.hide();
            $funcDesc.show();
        }

        if (value === "sub" || value === "func") {
            $localContainer.show();
        } else {
            $parameterContainer.hide();
            $localContainer.hide();
        }
    });

    $("#name").keyup(function() {
        comment.name = $("#name").val();
        C.utils.updateOutput(comment);
    });

    $("#assignment").keyup(function() {
        comment.setAssignment($("#assignment").val());
        C.utils.updateOutput(comment);
    });

    $("#obj-name").keyup(function() {
        comment.objectName = $("#obj-name").val();
        C.utils.updateOutput(comment);
    });

    $("#purpose").keyup(function() {
        comment.setPurpose($("#purpose").val());
        C.utils.updateOutput(comment);
    });

    $("#header-data").keyup(function() {
        try{
            var parseFunc = comment.commentType === "sub" ? C.utils.parseSubHeader : C.utils.parseFuncHeader,
                headerDict = parseFunc($("#header-data").val()),
                table = document.getElementById("parameters"),
                row,
                nameCol,
                descCol,
                parameter;
            $(table).find("tr").remove();
            comment.parameters = headerDict.parameters;
            comment.returns = new C.classes.ReturnType(headerDict.type);
            $("#header-data").css("color", "black");

            for (var i = 0; i < comment.parameters.length; ++i) {
                parameter = comment.parameters[i];
                parameter.id = C.utils.randomString(16);

                row = table.insertRow(-1);
                nameCol = row.insertCell(0);
                descCol = row.insertCell(1);

                $(row).attr("id", parameter.id);

                nameCol.innerHTML = parameter.name;
                descCol.outerHTML = "<input type='text' class='parameter-desc'>";
                parameter.addDescriptionListener();
            }

            $("#parameter-container").show();
            $("#return-container").show();
        } catch (e) {
            comment.parameters = [];

            $("#header-data").css("color", "red");
            $("#parameter-container").hide();
            $("#return-container").hide();
        } finally {
            C.utils.updateOutput(comment);
        }
    });

    $("#add-global").on("click", function() {
        var globalName = prompt("What is the name of the global variable?"),
            globalDesc = prompt("Please describe the global variable:"),
            globalId = C.utils.randomString(16),
            global = new C.classes.Variable(globalName, globalDesc, globalId, "global_vars"),
            table = document.getElementById("globals"),
            row = table.insertRow(-1),
            nameCol = row.insertCell(0),
            descCol = row.insertCell(1),
            deleteBtnCol = row.insertCell(2);

        comment.global_vars.push(global);

        nameCol.innerHTML = global.name;
        descCol.innerHTML = global.description;

        deleteBtnCol.outerHTML = "<button class='btn btn-danger-outline'><i class='fa fa-trash-o'></i></button>";

        $(row).attr("id", globalId);
        global.addDeleteListener();

        C.utils.updateOutput(comment);
    });

    $("#add-local").on("click", function() {
        var localName = prompt("What is the name of the local variable?"),
            localDesc = prompt("Please describe the local variable:"),
            localId = C.utils.randomString(16),
            local = new C.classes.Variable(localName, localDesc, localId, "local_vars"),
            table = document.getElementById("locals"),
            row = table.insertRow(-1),
            nameCol = row.insertCell(0),
            descCol = row.insertCell(1),
            deleteBtnCol = row.insertCell(2);

        comment.local_vars.push(local);

        nameCol.innerHTML = local.name;
        descCol.innerHTML = local.description;

        deleteBtnCol.outerHTML = "<button class='btn btn-danger-outline'><i class='fa fa-trash-o'></i></button>";

        $(row).attr("id", localId);
        local.addDeleteListener();

        C.utils.updateOutput(comment);
    });

    $("#return").keyup(function () {
        comment.returns.description = $("#return").val();
        C.utils.updateOutput(comment);
    });

    C.utils.updateOutput(comment);
})(jQuery, VbComment, moment, _);
