# Default Settings
set KAOSChannel 	"#bontang"
set KAOSPointsName 	"point"
set KAOSPointsPerAnswer 1500
set KAOSQuestionTime 	60
set KAOSMarker 		"*"
set KAOSScoreFile 	"kaos.scores"
set KAOSAskedFile	"kaos.asked"
set KAOSQuestionFile 	"scripts/question/kaos.db"
set KAOSCFGFile		"scripts/question/kaos.cfg"

# Channel Triggers
bind pub - !top KAOSTop10
bind pub - !toplast KAOSLastMonthTop3
bind pub - !poin KAOSPlayerScore
bind pub - !ulang KAOS_Repeat
bind pub - !cmds KAOSCmds
bind pub - !asked KAOS_ShowAsked
bind pub - !startbro KAOS_Start
bind pub - !beranay KAOS_Stop

# DCC Commands
bind dcc - kaosrehash dcc_kaosrehash
bind dcc - kaosanswer dcc_kaosanswer
bind dcc - kaosreset dcc_kaosresetasked
bind dcc - kaosasked dcc_kaosshowasked
bind dcc - kaosforce dcc_kaosforce

# Cron Bind For Monthly Score Reset
bind time - "00 00 01 * *" KAOS_NewMonth

# Global Variables
set KAOSRunning 0
set KAOSAllAnswered ""
set KAOSRoundOver ""
set KAOSQNumber 0
set KAOSQuestion 1
set KAOSQuestions(0) 0
set KAOSAsked 0
set KAOSMonthFileName ""
set KAOSQCount 0
set KAOSAnswerCount 1
set KAOSDisplayNum 1
set KAOSNumAnswered 1
set KAOSForced 0
set KAOSForcedQuestion 0
set KAOSAutoStart 1

# Scores And Ads
set KAOSAdNumber 0
set KAOSAd(0) "$botnick"
set KAOSAd(1) "$botnick"
set KAOSAd(2) "$botnick"
set KAOSLastMonthScores(0) "Nobody 0"
set KAOSLastMonthScores(1) "Nobody 0"
set KAOSLastMonthScores(2) "Nobody 0"

# Timers
set KAOSAdTimer ""
set KAOSQuestionTimer ""

# Version
set KDebug 0
set KAOSVersion "0.91.0"

#
# Start KAOS
#
proc KAOS_Start {nick uhost hand chan args} {
 global KAOSChannel KAOSRunning KAOSQCount KAOSQNumber KAOSQuestionFile KAOSAdNumber KAOSVersion KDebug

 if {($chan != $KAOSChannel)||($KAOSRunning != 0)} {return}

 set KAOSQCount 0
 set KAOSAdNumber 0

 KAOS_ReadCFG

 if {![file exist $KAOSQuestionFile]} {
   putcmdlog "\[KAOS\] Question File: $KAOSQuestionFile Unreadable Or Does Not Exist"
   return 0
 }

 set KAOSQCount [KAOS_ReadQuestionFile]

 if {$KAOSQCount < 2} {
   putcmdlog "\[KAOS\] Not Enough Questions in Question File $KAOSQuestionFile"
   return 0
 }

 set KAOSAskedFileLen [KAOS_ReadAskedFile]

 if {$KAOSAskedFileLen >= $KAOSQCount} {
   kaosmsg "[kaos] [kcr] All Questions Asked: Resetting \003"
   KAOS_ResetAsked
   return 0
 }

 set KAOSRunning 1

 kaosmsg "[kaos] [kcm] Kaos Games @Google.com \[$KAOSQCount Questions\] \003"

 bind pubm - "*" KAOSCheckGuess

 KAOSAskQuestion

 return 1
}

#
# Stop KAOS
#
proc KAOS_Stop {nick uhost hand chan args} {
 global KAOSChannel KAOSRunning KAOSQuestionTimer KAOSAdTimer


 if {($chan != $KAOSChannel)||($KAOSRunning != 1)} {return}

 set KAOSRunning 0

 catch {killutimer $KAOSQuestionTimer}
 catch {killutimer $KAOSAdTimer}

 catch {unbind pubm - "*" KAOSCheckGuess}

 kaosmsg "[kaos] \00306wekss.. diberhentiin dech ama \00304\[\00312$nick!$uhost\00304\]"
 return 1
}

#
# Pick Question
#
proc KAOSPickQuestion {} {
 global KAOSAsked KAOSQCount KDebug
 set KAOSUnasked [expr ($KAOSQCount - [llength $KAOSAsked])]
 if {$KAOSUnasked < 1} {
   kaosmsg "[kaos] [kcr] All Questions Asked: Resetting \003"
   KAOS_ResetAsked
 }
 set pickdone 0
 while {$pickdone == 0} {
  set kidx 0
  set foundinasked 0
  set pick [rand $KAOSQCount]
  while {[lindex $KAOSAsked $kidx] != ""} {
    if {[lindex $KAOSAsked $kidx] == $pick} {
     set foundinasked 1
     # kaoslog "KAOS" "Found Pick:$pick in Asked"
     break
    }
    incr kidx
  }
  if {$foundinasked == 0} {incr pickdone}
 }
 # kaoslog "KAOS" "Picked Question:$pick"
 KAOS_AddAsked $pick
 return $pick
}

#
# Parse Question
#
proc KAOSParseQuestion {QNum} {
 global KAOSMarker KAOSQuestions KAOSQuestion KAOSAnswers KAOSAnswerCount KAOSForcedQuestion KDebug

  set KAnswersLeft ""

  if {$QNum < 0} {
   set KAOSFileQuestion $KAOSForcedQuestion
  } {
   set KAOSFileQuestion $KAOSQuestions($QNum)
  }

  if {$KDebug > 1} {kaoslog "kaos" "Picked:$QNum Question:$KAOSFileQuestion"}

  if [info exists KAOSAnswers] {unset KAOSAnswers}

  # Position of first "*"

  set KAOSMarkerIDX [string first $KAOSMarker $KAOSFileQuestion]

  if {$KAOSMarkerIDX < 1} {
   kaoslog "KAOS" "Malformed Question #$QNum"
  }

  set KAOSQuestionEndIDX [expr $KAOSMarkerIDX - 1]

  set KAOSQuestion [string range $KAOSFileQuestion 0 $KAOSQuestionEndIDX]

  # Move to first character in answers
  incr KAOSMarkerIDX
  set KAnswersLeft [string range $KAOSFileQuestion $KAOSMarkerIDX end]

  set KDoneParsing 0
  set KAOSAnswerCount 0

  # Parse all answers

  while {$KDoneParsing != 1 } {
   set KAnswerEnd [string first $KAOSMarker $KAnswersLeft]

   if {$KAnswerEnd < 1} {
    set KDoneParsing 1
    set KAnswerEnd [string length $KAnswersLeft]
   }

   set KAnswer [string range $KAnswersLeft 0 [expr $KAnswerEnd -1]]

   set KAOSAnswers($KAOSAnswerCount) "# $KAnswer"

   set KAOSMarkerIDX [expr $KAnswerEnd +1]

   set KAnswersLeft [string range $KAnswersLeft $KAOSMarkerIDX end]
   incr KAOSAnswerCount
  }
}

#
# Ask Question
#
proc KAOSAskQuestion {} {
 global KAOSRunning KAOSQNumber KAOSAllAnswered KAOSRoundOver KAOSQuestion
 global KAOSPointsPerAnswer KAOSPointsName KAOSNumAnswered KAOSAnswerCount
 global KAOSQuestionTimer KAOSQuestionTime KAOSDisplayNum KAOSForced KAOSLastGuesser

 if {$KAOSRunning != 1} {return}

 # Get The Current Scores
 read_KAOSScore

 # Pick Next Question

  if {$KAOSForced == 1} {
  KAOSParseQuestion -1
  set KAOSQNumber 0
  set KAOSForced 0
  set KAOSForcedQuestion 0
 } {
  set KAOSQNumber [KAOSPickQuestion]
  KAOSParseQuestion $KAOSQNumber
 }

 set KAOSAllAnswered ""
 set KAOSLastGuesser ""
 set KAOSDisplayNum 0
 set KAOSNumAnswered 0
 set KAOSRoundOver ""

 # Choose Points Value For This Round
 set KAOSPointsPerAnswer [rand 50]
 if {$KAOSPointsPerAnswer < 1} {set KAOSPointsPerAnswer 50}
 set KAOSPointsPerAnswer [expr $KAOSPointsPerAnswer * 10]

 set KAOSPointTotal [expr $KAOSPointsPerAnswer *$KAOSAnswerCount]

 kaosmsg "[kcg] Soal : [kcb] $KAOSQuestion \003 \00306\[\00310$KAOSAnswerCount \00306Answers\]\003"
 kaosmsg "\00313$KAOSPointsPerAnswer \00312$KAOSPointsName \00306Untuk setiap jawaban yg benar. \00310Total: \00313$KAOSPointTotal \00312$KAOSPointsName\003"

 set KRemain [expr int([expr $KAOSQuestionTime /2])]
 set KAOSQuestionTimer [utimer $KRemain "KAOSDisplayRemainingTime $KRemain"]
}

#
# Get Player Guess
#

proc KAOSCheckGuess {nick uhost hand chan args} {
 global KAOSChannel KAOSRunning KAOSScore KAOSAnswerCount KAOSAnswers KAOSRoundOver
 global KAOSPointsName KAOSPointsPerAnswer KAOSNumAnswered KAOSAllAnswered KAOSLastGuesser KDebug

 if {($chan != $KAOSChannel)||($KAOSRunning != 1)||($KAOSRoundOver == 1)} {return}

 regsub -all \[{',.!}] $args "" args

 if {[string length args] == 0} {return}

 set KAOSGuessOld $args
 set KAOSGuess [string tolower $KAOSGuessOld]

 if {$KDebug > 1} {kaoslog "KAOS" "Guess: $nick $KAOSGuess"}

 foreach z [array names KAOSAnswers] {
  set KAOSTry [lrange $KAOSAnswers($z) 1 end] 
  set KAOSTryOld $KAOSTry

  regsub -all \[{',.!}] $KAOSTry "" KAOSTry

  set KAOSTry [string tolower $KAOSTry]
  if {$KDebug > 1} {kaoslog "KAOS" "Try: $KAOSTry"}

  if {$KAOSTry == $KAOSGuess} {
   if {[lindex $KAOSAnswers($z) 0] == "#"} {
    set KAOSAnswers($z) "$nick $KAOSGuessOld"
    kaosmsg "[knikclr $nick]\00306 menang \00313$KAOSPointsPerAnswer \00312$KAOSPointsName \00306untuk \00310$KAOSTryOld"
    incr KAOSNumAnswered
    if {$KAOSNumAnswered == $KAOSAnswerCount} {
     set KAOSAllAnswered 1
     set KAOSRoundOver 1
     set KAOSLastGuesser $nick
     kaosmsg "[kaos] [kcr] Pinter.... terjawab semuanya \003"
     KAOS_ShowResults
     KAOS_Recycle
    }
    return
   }
  }
 }
}

#
# Display Remaining Time And Answer Stats
#
proc KAOSDisplayRemainingTime {remaining} {
 global KAOSRunning KAOSAllAnswered KAOSNumAnswered KAOSAnswerCount KAOSQuestionTimer KAOSQuestionTime KAOSDisplayNum

 if {($KAOSRunning != 1)||($KAOSAllAnswered == 1)} {return}

 kaosmsg "\00312$remaining \00306detik lagi..."

 incr KAOSDisplayNum

 set KRemain [expr int([expr $KAOSQuestionTime /4])]

 if {$KAOSDisplayNum < 2} {
  set KAOSQuestionTimer [utimer $KRemain "KAOSDisplayRemainingTime $KRemain"]
 } {
  set KAOSQuestionTimer [utimer $KRemain KAOSTimesUp]
 }
}

#
# Show Results Of Round
#
proc KAOSTimesUp {} {
 global KAOSAnswers KAOSAllAnswered KAOSRoundOver KAOSNumAnswered KAOSAnswerCount KAOSQuestionTimer KAOSAdTimer

 if {$KAOSAllAnswered == 1} { return 1}

 set KAOSRoundOver 1

 set kaosmissed "[kcg] Waktu habis Critzz :P~...! \003 "

 append KMissed "\00304yang tidak terjawab: \00312"

 set KAnswersRemaining [expr ($KAOSAnswerCount - $KAOSNumAnswered)]

 set kcount 0
 foreach z [array names KAOSAnswers] {
  if {[lindex $KAOSAnswers($z) 0] == "#"} {
   append KMissed "\00312[lrange $KAOSAnswers($z) 1 end]"
   incr kcount
   if {$kcount < $KAnswersRemaining} {append KMissed " \00311| "}
  }
 }

 kaosmsg "$KMissed\003"

 KAOS_ShowResults

 if {$KAOSNumAnswered > 0} {
  kaosmsg "[kcs] Soal yang terjawab:  $KAOSNumAnswered dari $KAOSAnswerCount! \003"
 } {
  kaosmsg "[kaos] \00304Busyett! \00310Gak ada yg tau jawabannya !!, pada mojok ya... \003"
 }

 set KAOSAdTimer [utimer 10 KAOS_ShowAd]

 set KAOSQuestionTimer [utimer 20 KAOSAskQuestion]
}

#
# All Answers Gotten, Next Question
#
proc KAOS_Recycle {} {
 global KAOSAnswers KAOSNumAnswered KAOSQuestionTimer KAOSAdTimer
 catch {killutimer $KAOSQuestionTimer}
 if [info exists KAOSAnswers] {unset KAOSAnswers}
 set KAOSAdTimer [utimer 10 KAOS_ShowAd]
 set KAOSQuestion 0
 set KAOSNumAnswered 0
 set KAOSQuestionTimer [utimer 20 KAOSAskQuestion]
}

#
# Total Answers and Points
#
proc KAOS_ShowResults {} {
 global KAOSAnswers KAOSPointsPerAnswer KAOSPointsName KAOSScore KAOSAllAnswered KAOSLastGuesser

 set NickCounter 0
 set KAOSCounter 0

 if {$KAOSAllAnswered == 1} {
  set KAOSBonus [expr $KAOSPointsPerAnswer *10]
  kaosmsg "[knikclr $KAOSLastGuesser]\00306 mendapatkan \00313$KAOSBonus \00312Bonus $KAOSPointsName \00306karena bisa menjawab jawaban tertinggi!"
  set KNickTotals($KAOSLastGuesser) $KAOSBonus
  set KNickList($NickCounter) $KAOSLastGuesser
  incr NickCounter
 }

 foreach z [array names KAOSAnswers] {
  if {[lindex $KAOSAnswers($z) 0] != "#"} {
   set cnick [lindex $KAOSAnswers($z) 0]
   if {[info exists KNickTotals($cnick)]} {
    incr KNickTotals($cnick) $KAOSPointsPerAnswer
   } {
    set KNickTotals($cnick) $KAOSPointsPerAnswer
    set KNickList($NickCounter) $cnick
    incr NickCounter
   }
   incr KAOSCounter
  }
 }

 if {$KAOSCounter > 0} {
  set ncount 0
  set nicktotal "[kcm] $KAOSPointsName This Round "
  while {$ncount < $NickCounter} {
   set cnick $KNickList($ncount)
   if {[info exists KAOSScore($cnick)]} {
     incr KAOSScore($cnick) $KNickTotals($cnick)
   } {
     set KAOSScore($cnick) $KNickTotals($cnick)
   }
   append nicktotal "[kcc] $cnick [kcm] $KNickTotals($cnick) "
   incr ncount
  }
  kaosmsg $nicktotal
  write_KAOSScore
 }
}

#
# Read Scores
#
proc read_KAOSScore { } {
 global KAOSScore KAOSScoreFile
 if [info exists KAOSScore] { unset KAOSScore }
 if {[file exists $KAOSScoreFile]} {
  set f [open $KAOSScoreFile r]
  while {[gets $f s] != -1} {
   set KAOSScore([lindex $s 0]) [lindex $s 1]
  }
  close $f
  } {
   set f [open $KAOSScoreFile w]
   puts $f "Nobody 0"
   close $f
  }
}

#
# Write Scores
#
proc write_KAOSScore {} {
 global KAOSScore KAOSScoreFile
 set f [open $KAOSScoreFile w]
 foreach s [lsort -decreasing -command sort_KAOSScore [array names KAOSScore]] {
  puts $f "$s $KAOSScore($s)"
 }
 close $f
}

#
# Score Sorting
#
proc sort_KAOSScore {s1 s2} {
 global KAOSScore
 if {$KAOSScore($s1) >  $KAOSScore($s2)} {return 1}
 if {$KAOSScore($s1) <  $KAOSScore($s2)} {return -1}
 if {$KAOSScore($s1) == $KAOSScore($s2)} {return 0}
}

#
# Add Question Number To Asked File
#
proc KAOS_AddAsked {KQnum} {
 global KAOSAsked KAOSAskedFile
 set f [open $KAOSAskedFile a]
 puts $f $KQnum
 close $f
 lappend KAOSAsked $KQnum
}

#
# Parse Asked Questions
#
proc KAOS_ReadAskedFile {} {
 global KAOSAsked KAOSAskedFile
 set KAsked 0
 set KAOSAsked 0
 if {![file exists $KAOSAskedFile]} {
  set f [open $KAOSAskedFile w]
 } {
  set f [open $KAOSAskedFile r]
  while {[gets $f KQnum] != -1} {
   lappend KAOSAsked "$KQnum"
   incr KAsked
  }
 }
 close $f
 return $KAsked
}

#
# Reset Asked File
#
proc KAOS_ResetAsked {} {
 global KAOSAskedFile KAOSAsked
 set f [open $KAOSAskedFile w]
 puts $f "0"
 close $f
 set KAOSAsked 0
}

#
# Read Question File
#
proc KAOS_ReadQuestionFile {} {
 global KAOSQuestionFile KAOSQuestions
 set KQuestions 0
 set f [open $KAOSQuestionFile r]
 while {[gets $f q] != -1} {
  set KAOSQuestions($KQuestions) $q
  incr KQuestions
 }
 close $f
 return $KQuestions
}

#
# Show Asked
#
proc KAOS_ShowAsked {nick uhost hand chan args} {
 global KAOSQCount KAOSAsked KAOSQuestions
 set KAOSStatsAsked [llength $KAOSAsked]
 set KAOSStatsUnasked [expr ($KAOSQCount - $KAOSStatsAsked)]
 kaosmsg "[kaos] [kcm] Total: [kcc] $KAOSQCount [kcm] Asked: [kcc] $KAOSStatsAsked [kcm] Remaining: [kcc] $KAOSStatsUnasked \003"
}

#
# Repeat Question
#
proc KAOS_Repeat {nick uhost hand chan args} {
 global KAOSChannel KAOSQuestion KAOSRunning KAOSQNumber KAOSAllAnswered
 global KAOSPointsName
 if {($chan != $KAOSChannel)||($KAOSRunning != 1)} {return}
 if {$KAOSAllAnswered == 1} {return }
 kaosmsg "\00300,03 K[format "%04d" $KAOSQNumber] \00308,02 $KAOSQuestion \003"
}

#
# Display User's Score
#
proc KAOSPlayerScore {nick uhost hand chan args} {
 global KAOSChannel KAOSScoreFile KAOSPointsName

 if {$chan != $KAOSChannel} {return}

 regsub -all \[`,.!{}] $args "" args

 if {[string length $args] == 0} {set args $nick}

 set scorer [string tolower $args]

 set kflag 0

 set f [open $KAOSScoreFile r]
 while {[gets $f sc] != -1} {
  set cnick [string tolower [lindex $sc 0]]
  if {$cnick == $scorer} {

   kaosmsg "[kcm] [lindex $sc 0] [kcc] [lindex $sc 1] $KAOSPointsName \003"
   set kflag 1
  }
 }
 if {$kflag == 0} {kaosmsg "[kcm] $scorer [kcc] No Score \003"}
 close $f
}

#
# Display Top 10 Scores To A Player
#
proc KAOSTop10 {nick uhost hand chan args} {
 global KAOSChannel KAOSScoreFile KAOSPointsName
 if {$chan != $KAOSChannel} {return}
 set KWinners "[kcm] Top10 Game $KAOSPointsName "
 set f [open $KAOSScoreFile r]
 for { set s 0 } { $s < 10 } { incr s } {
  gets $f KAOSTotals
  if {[lindex $KAOSTotals 1] > 0} {
   append KWinners "[kcm] #[expr $s +1] [kcc] [lindex $KAOSTotals 0] [lindex $KAOSTotals 1] "
  } {
   append KWinners "[kcm] #[expr $s +1] [kcc] Nobody 0 "
  }
 }
 kaosmsg "$KWinners"
 close $f
}

#
# Last Month's Top 3
#
proc KAOSLastMonthTop3 {nick uhost hand chan args} {
 global KAOSChannel KAOSLastMonthScores
 if {$chan != $KAOSChannel} {return}
 if [info exists KAOSLastMonthScores] {
  set KWinners "[kcm] Last Month's Game Top 3 "
  for { set s 0} { $s < 3 } { incr s} {
   append KWinners "[kcm] #[expr $s +1] [kcc] $KAOSLastMonthScores($s) "
  }
  kaosmsg "$KWinners"
 }
}

#
# Read Config File
#
proc KAOS_ReadCFG {} {
 global KAOSCFGFile KAOSChannel KAOSAutoStart KAOSScoreFile KAOSAskedFile KAOSQuestionFile KAOSLastMonthScores KAOSPointsName KAOSAd
 if {[file exist $KAOSCFGFile]} {
  set f [open $KAOSCFGFile r]
  while {[gets $f s] != -1} {
   set kkey [string tolower [lindex [split $s "="] 0]]
   set kval [lindex [split $s "="] 1]
   switch $kkey {
    points { set KAOSPointsName $kval }
    channel { set KAOSChannel $kval }
    autostart { set KAOSAutoStart $kval }
    scorefile { set KAOSScoreFile $kval }
    askedfile { set KAOSAskedFile $kval }
    kaosfile { set KAOSQuestionFile $kval }
    ad1 { set KAOSAd(0) $kval }
    ad2 { set KAOSAd(1) $kval }
    ad3 { set KAOSAd(2) $kval }
    lastmonth1 { set KAOSLastMonthScores(0) $kval }
    lastmonth2 { set KAOSLastMonthScores(1) $kval }
    lastmonth3 { set KAOSLastMonthScores(2) $kval }
   }
  }
  close $f
  if {($KAOSAutoStart < 0)||($KAOSAutoStart > 1)} {set KAOSAutoStart 1}
  return
 }
 kaoslog "KAOS" "Config file $KAOSCFGFile not found... using defaults"
}

#
# Write Config File
#
proc KAOS_WriteCFG {} {
 global KAOSCFGFile KAOSChannel KAOSAutoStart KAOSScoreFile KAOSAskedFile KAOSQuestionFile KAOSLastMonthScores KAOSPointsName KAOSAd
 set f [open $KAOSCFGFile w]
 puts $f "# This file is automatically overwritten"
 puts $f "Points=$KAOSPointsName"
 puts $f "Channel=$KAOSChannel"
 puts $f "AutoStart=$KAOSAutoStart"
 puts $f "ScoreFile=$KAOSScoreFile"
 puts $f "AskedFile=$KAOSAskedFile"
 puts $f "KAOSFile=$KAOSQuestionFile"
 puts $f "LastMonth1=$KAOSLastMonthScores(0)"
 puts $f "LastMonth2=$KAOSLastMonthScores(1)"
 puts $f "LastMonth3=$KAOSLastMonthScores(2)"
 puts $f "Ad1=$KAOSAd(0)"
 puts $f "Ad2=$KAOSAd(1)"
 puts $f "Ad3=$KAOSAd(2)"
 close $f
}

#
# Clear Month's Top 10
#
proc KAOS_NewMonth {min hour day month year} {
 global KAOSScoreFile KAOSScore KAOSLastMonthScores

 set cmonth [expr $month +1]
 set lmonth [KAOSLastMonthName $cmonth]

 kaosmsg "[kaos] [kcr] Clearing Monthly Scores \003"

 set KAOSMonthFileName "$KAOSScoreFile.$lmonth"

 set f [open $KAOSMonthFileName w]
 set s 0
 foreach n [lsort -decreasing -command sort_KAOSScore [array names KAOSScore]] {
  puts $f "$n $KAOSScore($n)"
  if {$s < 3} {
   if {$KAOSScore($n) > 0} {
    set KAOSLastMonthScores($s) "$n $KAOSScore($n)"
   } {
    set KAOSLastMonthScores($s) "Nobody 0"
   }
  }
  incr s
 }
 close $f

 KAOS_WriteCFG

 if [info exists KAOSScore] {unset KAOSScore}

 set f [open $KAOSScoreFile w]
 puts $f "Nobody 0"
 close $f

 putcmdlog "\[KAOS\] Cleared Monthly Top10 Scores: $KAOSMonthFileName"
}

#
# Command Help
#
proc KAOSCmds {nick uhost hand chan args} {
 global KAOSChannel
 if {$chan != $KAOSChannel} {return}
 kaosntc $nick "KAOS Commands: !top10 !poin \[nick\] !ulang !asked"
}

#
# Color Routines
#
proc kcb {} {
 return "\0038,2"
}
proc kcg {} {
 return "\0030,3"
}
proc kcr {} {
 return "\0030,4"
}
proc kcm {} {
 return "\0030,6"
}
proc kcc {} {
 return "\0030,10"
}
proc kcs {} {
 return "\0030,12"
}
proc kaos {} {
 return ""
}

# Channel Message
proc kaosmsg {what} {
 global KAOSChannel
 putquick "PRIVMSG $KAOSChannel :$what"
}

# Notice Message
proc kaosntc {who what} {
 putquick "NOTICE $who :$what"
}
# Command Log
proc kaoslog {who what} {
 putcmdlog "\[$who\] $what"
}

# Name Of Last Month
proc KAOSLastMonthName {month} {
 switch $month {
  1 {return "Dec"}
  2 {return "Jan"}
  3 {return "Feb"}
  4 {return "Mar"}
  5 {return "Apr"}
  6 {return "May"}
  7 {return "Jun"}
  8 {return "Jul"}
  9 {return "Aug"}
  10 {return "Sep"}
  11 {return "Oct"}
  12 {return "Nov"}
  default {return "???"}
 }
}

# Assign Nickname Color
proc knikclr {nick} {
  set nicklen [strlen $nick]
  set nicktot 0
  set c 0
  while {$c < $nicklen} {
   binary scan [string range $nick $c $c] c nv
   incr nicktot [expr $nv -32]
   incr c
  }
  set nickclr [expr $nicktot %13]
  switch $nickclr {
   0 {set nickclr 10}
   1 {set nickclr 11}
   2 {set nickclr 12}
   5 {set nickclr 13}
  }
  set nik [format "%02d" $nickclr]
  return "\003$nik$nick"
}

#
# Show Ad
#
proc KAOS_ShowAd {} {
 global KAOSAdNumber KAOSAd botnick KAOSChannel
 switch $KAOSAdNumber {
  0 { kaosmsg "[kcs] $KAOSAd(0) \003" }
  1 { KAOSTop10 $botnick none none $KAOSChannel none }
  2 { kaosmsg "[kcs] $KAOSAd(1) \003" }
  3 { KAOSLastMonthTop3 $botnick none none $KAOSChannel none }
  4 { kaosmsg "[kcs] $KAOSAd(2) \003" }
 }
 incr KAOSAdNumber
 if {$KAOSAdNumber > 4} {set KAOSAdNumber 0}
}

#
# Rehash KAOS Config
#
proc dcc_kaosrehash {hand idx arg} {
 global KAOSQCount

 putcmdlog "#$hand# Rehashing KAOS config"

 KAOS_ReadCFG

 set KAOSQCount [KAOS_ReadQuestionFile]

 if {$KAOSQCount < 2} {
   kaoslog "KAOS" "Not Enough Questions in Question File $KAOSQuestionFile"
   return 0
 }

 set KAOSAskedFileLen [KAOS_ReadAskedFile]

 if {$KAOSAskedFileLen >= $KAOSQCount} {
   kaoslog "KAOS" "Asked file out of sync with question database: resetting"
   KAOS_ResetAsked
   return 0
 }
 kaoslog "KAOS" "Questions:$KAOSQCount Asked:$KAOSAskedFileLen Remaining:[expr ($KAOSQCount - $KAOSAskedFileLen)]"
}

#
# Show Current Answers
#
proc dcc_kaosanswer {hand idx arg} {
 global KAOSAnswers
 set ans ""
 foreach z [array names KAOSAnswers] {
  if {[lindex $KAOSAnswers($z) 0] == "#"} {
   append ans "[lrange $KAOSAnswers($z) 1 end] | "
  }
 }
 kaoslog "KAOS" $ans
}

#
# Reset Asked File
#
proc dcc_kaosresetasked {hand idx arg} {
 KAOS_ResetAsked
 kaoslog "KAOS" "#$hand# Reset Asked File"
}

#
# Show Asked
#
proc dcc_kaosshowasked {hand idx arg} {
 global KAOSQCount KAOSAsked KAOSQuestions
 set KAOSStatsAsked [llength $KAOSAsked]
 set KAOSStatsUnasked [expr ($KAOSQCount - $KAOSStatsAsked)]
 kaoslog "KAOS" "Total:$KAOSQCount  Asked:$KAOSStatsAsked  Remaining:$KAOSStatsUnasked"
}

#
# Force A Question
#
proc dcc_kaosforce {hand idx arg} {
 global KAOSRunning KAOSMarker KAOSForced KAOSForcedQuestion
 if {$KAOSRunning != 1} {return}
 regsub -all \[`,.!{}] $arg "" arg
 if {$arg == ""} {return}
 set KAOSMarkerIDX [string first $KAOSMarker $arg]
 if {$KAOSMarkerIDX < 2} {
  kaoslog "KAOS" "Malformed question: Format: Question*Answer1*Answer2..."
  return
 }
 set KAOSForcedQuestion $arg
 set KAOSForced 1
 kaoslog "KAOS" "Forcing A Question Next Round"
}

KAOS_ReadCFG

putcmdlog "Loaded KAOS $KAOSVersion by Indra^Pratama"
