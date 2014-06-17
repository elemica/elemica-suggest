// Generated by CoffeeScript 1.7.1
(function() {
  (function($) {
    return $.fn.extend({
      elemicaSuggest: function(options) {
        var $valueInput, BACKSPACE, DOWN_ARROW, ENTER, TAB, UP_ARROW, afterSuggest, highlightAnother, highlightNext, highlightPrevious, minimumSearchTermLength, noMatchesMessage, populateSuggestions, removeSuggestions, selectHighlighted, selectionIndicatorTarget, suggestFunction;
        if (options == null) {
          options = {};
        }
        UP_ARROW = 38;
        DOWN_ARROW = 40;
        ENTER = 13;
        TAB = 9;
        BACKSPACE = 8;
        suggestFunction = options.suggestFunction || function(term, _) {
          return typeof console !== "undefined" && console !== null ? console.warn("No suggest function defined.") : void 0;
        };
        minimumSearchTermLength = options.minimumSearchTermLength || 2;
        $valueInput = options.valueInput || $("<input />");
        selectionIndicatorTarget = options.selectionIndicatorTarget || function($target) {
          return $target;
        };
        noMatchesMessage = options.noMatchesMessage || $(this.first()).data('no-matches');
        afterSuggest = options.afterSuggest || function() {};
        removeSuggestions = function(element) {
          return $(element).siblings(".suggestions").remove();
        };
        highlightAnother = function(element, otherCalcFunc) {
          var $currentActive, $nextElement;
          $currentActive = $(element).parent().find(".suggestions > .active");
          $nextElement = otherCalcFunc($currentActive);
          if ($currentActive.length && $nextElement.length) {
            $currentActive.removeClass("active");
            return $nextElement.addClass("active");
          } else if (!$currentActive.length) {
            return $(element).parent().find(".suggestions > li:first-child").addClass("active");
          }
        };
        highlightNext = function(element) {
          return highlightAnother(element, function($currentActive) {
            return $currentActive.next();
          });
        };
        highlightPrevious = function(element) {
          return highlightAnother(element, function($currentActive) {
            return $currentActive.prev();
          });
        };
        selectHighlighted = function(element) {
          $(element).parent().find(".suggestions .active").trigger("element-selected").end().end().trigger("blur").trigger("focus");
          return selectionIndicatorTarget($(element)).addClass("has-selection");
        };
        populateSuggestions = function(element) {
          return function(suggestions) {
            var $suggestionsList, suggestion;
            $suggestionsList = $(element).siblings(".suggestions");
            if ($suggestionsList.length === 0) {
              $suggestionsList = $("<ul />").addClass("suggestions");
              $(element).parent().append($suggestionsList);
            }
            $suggestionsList.empty().append((function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = suggestions.length; _i < _len; _i++) {
                suggestion = suggestions[_i];
                _results.push((function(suggestion) {
                  var $suggestionLi;
                  $suggestionLi = $("<li />").text(suggestion.display).on('mousedown element-selected', function() {
                    $(element).val(suggestion.display);
                    return $valueInput.val(suggestion.value);
                  }).on('mouseover', function() {
                    return $(this).siblings().removeClass("active").end().addClass("active");
                  });
                  if (suggestion.image != null) {
                    $suggestionLi.prepend($("<img />").attr("src", suggestion.image));
                  }
                  if (suggestion.metadata != null) {
                    $suggestionLi.append($("<span />").text(suggestion.metadata).addClass("metadata"));
                  }
                  return $suggestionLi;
                })(suggestion));
              }
              return _results;
            })()).find("li:first-child").addClass("active");
            if (suggestions.length === 0) {
              $suggestionsList.append($("<li />").text(noMatchesMessage).addClass("invalid-text"));
            }
            return afterSuggest();
          };
        };
        return this.each(function() {
          $(this).attr('autocomplete', 'off');
          $(this).on('blur', function(event) {
            removeSuggestions(event.target);
            if ($valueInput.val() === "") {
              return $(event.target).val("");
            }
          });
          $(this).on('keydown', (function(_this) {
            return function(event) {
              if (event.keyCode === UP_ARROW || event.keyCode === DOWN_ARROW || event.keyCode === ENTER) {
                return event.preventDefault();
              } else if (event.keyCode === TAB) {
                return selectHighlighted(_this);
              } else if (event.keyCode === BACKSPACE && $valueInput.val() !== "") {
                $valueInput.val("");
                return $(event.target).val("");
              }
            };
          })(this));
          return $(this).on('keyup', (function(_this) {
            return function(event) {
              var $target, searchTerm;
              switch (event.keyCode) {
                case UP_ARROW:
                  return highlightPrevious(_this);
                case DOWN_ARROW:
                  return highlightNext(_this);
                case ENTER:
                  return selectHighlighted(_this);
                default:
                  $valueInput.val("");
                  $target = $(event.target);
                  selectionIndicatorTarget($target).removeClass("has-selection");
                  searchTerm = $.trim($target.val());
                  if (searchTerm.length >= minimumSearchTermLength) {
                    return suggestFunction(searchTerm, populateSuggestions(_this));
                  } else {
                    return removeSuggestions(_this);
                  }
              }
            };
          })(this));
        });
      }
    });
  })(jQuery);

}).call(this);
