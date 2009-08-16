/**
 * Ruby syntax v 1.0 
 * 
 * v1.0 by Patrice De Saint Steban (2007/01/03)
 *   
**/
editAreaLoader.load_syntax["ruby"] = {
	'COMMENT_SINGLE' : {1 : '#'}
	,'COMMENT_MULTI' : {}
	,'QUOTEMARKS' : {1: "'", 2: '"'}
	,'KEYWORD_CASE_SENSITIVE' : true
	,'KEYWORDS' : {
		'reserved' : [
			'alias', 'and', 'BEGIN', 'begin', 'break', 'case', 'class', 'def', 'defined', 'do', 'else',
			'elsif', 'END', 'end', 'ensure', 'false', 'for', 'if', 
			'in', 'module', 'next', 'not', 'or', 'redo', 'rescue', 'retry',
			'return', 'self', 'super', 'then', 'true', 'undef', 'unless', 'until', 'when', 'while', 'yield'
		]
	}
	,'OPERATORS' :[
		'+', '-', '/', '*', '=', '<', '>', '%', '!', '&', ';', '?', '`', ':', ','
	]
	,'DELIMITERS' :[
		'(', ')', '[', ']', '{', '}'
	]
	,'REGEXPS' : {
		'constants' : {
			'search' : '()([A-Z]\\w*)()'
			,'class' : 'constants'
			,'modifiers' : 'g'
			,'execute' : 'before' 
		}
		,'variables' : {
			'search' : '()([\$\@\%]+\\w+)()'
			,'class' : 'variables'
			,'modifiers' : 'g'
			,'execute' : 'before' 
		}
		,'numbers' : {
			'search' : '()(-?[0-9]+)()'
			,'class' : 'numbers'
			,'modifiers' : 'g'
			,'execute' : 'before' 
		}
		,'symbols' : {
			'search' : '()(:\\w+)()'
			,'class' : 'symbols'
			,'modifiers' : 'g'
			,'execute' : 'before'
		}
	}
	,'STYLES' : {
		'COMMENTS': 'color: #3F7F5F;'
		,'QUOTESMARKS': 'color: #999999;'
		,'KEYWORDS' : {
			'reserved' : 'color: #A4357A;'
			}
		,'OPERATORS' : 'color: #003399;'
		,'DELIMITERS' : 'color: #003399;'
		,'REGEXPS' : {
			'variables' : 'color: #004080;'
			,'numbers' : 'color: #0080FF;'
			,'constants' : 'color: #777777;'
			,'symbols' : 'color: #FF3030;'
		}	
	}
};
