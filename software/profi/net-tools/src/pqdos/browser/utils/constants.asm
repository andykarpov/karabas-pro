TAB = 9
CR = 13
LF = 10
NULL = 0
SPACE = ' '
ESC = 27
BACKSPACE = 8

MIME_DOWNLOAD = 1
MIME_LINK = 2
MIME_TEXT = 3
MIME_IMAGE = 4
MIME_MUSIC = 5
MIME_INPUT = 6

BORDER_TOP    = 7
BORDER_BOTTOM = 8

sepparators db CR, LF, TAB, NULL, SPACE
sepparators_len = $ - sepparators