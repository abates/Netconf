

$LOAD_PATH << File.expand_path("../../lib", __FILE__)
require "netconf"
require "~/.naptime"

# setup ANSI color codes
@text_normal = "\033[0m"  #  Turn off all attributes
@text_bright = "\033[1m"  #  Set bright mode
@text_underline = "\033[4m"  #  Set underline mode
@text_blink = "\033[5m"  #  Set blink mode
@text_reverse = "\033[7m"  #  Exchange foreground and background colors
@text_hide = "\033[8m"  #  Hide text (foreground color would be the same as background)
@text_black = "\033[30m" #  Black text
@text_red = "\033[31m" #  Red text
@text_green = "\033[32m" #  Green text
@text_yellow = "\033[33m" #  Yellow text
@text_blue = "\033[34m" #  Blue text
@text_magenta = "\033[35m" #  Magenta text
@text_cyan = "\033[36m" #  Cyan text
@text_white = "\033[37m" #  White text
@text_default = "\033[39m" #  Default text color
@background_black = "\033[40m" #  Black background
@background_red = "\033[41m" #  Red background
@background_green = "\033[42m" #  Green background
@background_yellow = "\033[43m" #  Yellow background
@background_blue = "\033[44m" #  Blue background
@background_magenta = "\033[45m" #  Magenta background
@background_cyan = "\033[46m" #  Cyan background
@background_white = "\033[47m" #  White background
@background_default = "\033[49m" #  Default background color

