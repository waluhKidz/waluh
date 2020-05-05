# what channel(s) do you want this to be active on?
set mc_re(chan) "#bontang"

# add as many as you want, it goes 
# ` set mc_resp( <wild card'd word(s)> ) { <if match, what to say in 
#                                         the channel as a response to the match> }
set mc_resp(*assalam*) "Wa'alaikumsalam Warrahmatullahi Wabarokaatuh ..... %nick"

### ^^^ valid veriables are %nick %uhost %hand %chan ^^^ ###

### stop editing, coding starts here ###
set mc_re(version) v1.1
set mc_re(chan) [string tolower $mc_re(chan)]
bind pubm - * mc:resp
proc mc:resp {nick uhost hand chan args} {
 global mc_resp mc_re ; set args [string tolower [lindex $args 0]]
 if {[lsearch -exact $mc_re(chan) [string tolower $chan]] == "-1"} {return 0}
 foreach search [string tolower [array names mc_resp]] {
  if {[string match $search $args]} {
   if {[string match *\n* $mc_resp($search)]} {
    foreach post [mc:resp:rep $mc_resp($search) $nick $uhost $hand $chan] {
     puthelp "PRIVMSG $chan :$post"
    } ; break
   } {
    puthelp "PRIVMSG $chan :[mc:resp:rep $mc_resp($search) $nick $uhost $hand $chan]"
   }
  }
 }
}

proc mc:resp:rep {data nick uhost hand chan} {
 global botnick
 regsub -all -- %nick $data $nick data ; regsub -all -- %uhost $data $uhost data
 regsub -all -- %botnick $data $botnick data
 regsub -all -- %hand $data $hand data ; regsub -all -- %chan $data $chan data
 regsub -all -- %b $data  data ; regsub -all -- %r $data  data
 regsub -all -- %u $data  data ; regsub -all -- %c $data  data
 return $data
}

putlog "Respond $mc_re(version) loaded"
