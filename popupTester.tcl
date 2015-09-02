#
#Copyright (c) 2011, Vasileios I. Anagnostopoulos (ICCS)
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is furnished
#to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#This file is part of ScovisAnnotator.
#
#    ScovisAnnotator is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    ScovisAnnotator is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with ScovisAnnotator.  If not, see <http://www.gnu.org/licenses/>.

package require Tk

namespace eval ::canvasstate {
	set mycanvas .t.frameshow.canvas
	set option_selection 1
	set label_selection "Label"
	set x 0
	set rectangles [list ]
	set prev_rectangles [list ]
	set current_activity "UnknownActivity"
	set prev_activity ""
	set prev_text [list ]
	set control_points [list ]	
	set MoverX 0
	set MoverY 0
}

proc inside_rectangle {wherex wherey rect} {	
	set insider 1
	set flag [expr { $wherex >= [lindex $rect 0] } ]
	set insider [expr {$insider && $flag } ]	
	set flag [expr {$wherex <= [lindex $rect 2] } ]
	set insider [expr {$insider && $flag }]
	set flag [expr {$wherey >= [lindex $rect 1]}]
	set insider [expr {$insider && $flag }]
	set flag [expr {$wherey <= [lindex $rect 3]}]
	set insider [expr {$insider && $flag}]
	
	return $insider
}

proc popup_on_rectangle {args} {	
	set ::canvasstate::Id $args	
	set workingRectangle [lindex $::canvasstate::rectangles  $::canvasstate::Id]	
	set ::canvasstate::option_selection 2
	set ::canvasstate::label_selection [lindex $workingRectangle 2]
	
	toplevel .fpop
	update
	grab .fpop
	wm title .fpop "Manipulate BB"
	labelframe .fpop.up -text "Command selection"
	labelframe .fpop.down -text "Label insertion"
	button .fpop.but -text "Accept" -command "dismiss_proc" -underline 0
	bind .fpop.but <a> {.fpop.but invoke}
	focus .fpop.but
	grid .fpop.up
	grid .fpop.down
	grid .fpop.but
				
	grid rowconfigure .fpop .fpop.up -weight 1
	grid rowconfigure .fpop .fpop.down -weight 1
	
	radiobutton .fpop.up.b1 -text "Delete" -value 1 -variable ::canvasstate::option_selection \
	    -relief flat -tristatevalue "multi"   -command "arm_entry 0"
    	pack .fpop.up.b1
	
	radiobutton .fpop.up.b2 -text "Resize" -value 2 -variable ::canvasstate::option_selection  \
	    -relief flat -tristatevalue "multi"   -command "arm_entry 0"
	pack .fpop.up.b2

	
	radiobutton .fpop.up.b3 -text "Label" -value 3 -variable ::canvasstate::option_selection  \
	    -relief flat -tristatevalue "multi"  -command "arm_entry 1"
	pack .fpop.up.b3
	
	entry .fpop.down.en -relief sunken -textvariable ::canvasstate::label_selection -state "normal"
	pack .fpop.down.en
}

proc DeleteCmd {} {
	set workingRectangle [lindex $::canvasstate::rectangles  $::canvasstate::Id]
	$::canvasstate::mycanvas delete [lindex $workingRectangle 0]
	$::canvasstate::mycanvas delete [lindex $workingRectangle 1]
	set ::canvasstate::rectangles [lreplace $::canvasstate::rectangles $::canvasstate::Id $::canvasstate::Id] 
}

proc LabelCmd {  } {
	set workingRectangle [lindex $::canvasstate::rectangles  $::canvasstate::Id]
	set workingRectangle [lreplace $workingRectangle 2 2 $::canvasstate::label_selection ]
	set ::canvasstate::rectangles [lreplace $::canvasstate::rectangles $::canvasstate::Id  $::canvasstate::Id $workingRectangle]
	$::canvasstate::mycanvas itemconfigure [lindex $workingRectangle 1] -text $::canvasstate::label_selection
}

proc ActivateForResize {  } {
	set workingRectangle [lindex $::canvasstate::rectangles  $::canvasstate::Id]
	set somecoords [$::canvasstate::mycanvas coords [lindex $workingRectangle 0]]
	set temp1 [lindex $somecoords 0]
	set temp2 [lindex $somecoords 2]	
	set dx [ expr  {$temp2 - $temp1} ]
	set dx [expr {$dx / 2 }]
	set centralx [expr {$dx + $temp1  }]
	set temp1 [lindex $somecoords 1]
	set temp2 [lindex $somecoords 3]	
	set dy [ expr  {$temp2 - $temp1}]
	set dy [expr {$dy / 2 }]
	set centraly [expr {$dy + $temp1  }]
	set help_cp [ list [expr {$centralx - 5} ]  [expr {$centraly - 5} ]\
	 		[expr {$centralx + 5}] [expr {$centraly + 5}] ]
	$::canvasstate::mycanvas create rectangle $help_cp -fill white -tag tag_central

	set centralx [lindex $somecoords 0]
	set centraly [lindex $somecoords 1]
	
	set help_cp [ list [expr {$centralx - 5} ]  [expr {$centraly - 5} ]\
	 		[expr {$centralx + 5}] [expr {$centraly + 5}] ]
	$::canvasstate::mycanvas create rectangle $help_cp -fill white -tag tag_nw

	set centralx [lindex $somecoords 0]
	set centraly [lindex $somecoords 3]
	
	set help_cp [ list [expr {$centralx - 5} ]  [expr {$centraly - 5} ]\
	 		[expr {$centralx + 5}] [expr {$centraly + 5}] ]
	$::canvasstate::mycanvas create rectangle $help_cp -fill white -tag tag_sw
	
	set centralx [lindex $somecoords 2]
	set centraly [lindex $somecoords 1]
	
	set help_cp [ list [expr {$centralx - 5} ]  [expr {$centraly - 5} ]\
	 		[expr {$centralx + 5}] [expr {$centraly + 5}] ]
	$::canvasstate::mycanvas create rectangle $help_cp -fill white -tag tag_ne

	set centralx [lindex $somecoords 2]
	set centraly [lindex $somecoords 3]
	
	set help_cp [ list [expr {$centralx - 5} ]  [expr {$centraly - 5} ]\
	 		[expr {$centralx + 5}] [expr {$centraly + 5}] ]
	$::canvasstate::mycanvas create rectangle $help_cp -fill white -tag tag_se

	set ::canvasstate::control_points [list tag_central tag_nw tag_sw tag_ne tag_se]
	$::canvasstate::mycanvas bind tag_central <1> {savepos %W %x %y}
	$::canvasstate::mycanvas bind tag_central  <B1-Motion> {resize_cp %W 0 %x %y}
	$::canvasstate::mycanvas bind tag_nw <1> {savepos %W %x %y}
	$::canvasstate::mycanvas bind tag_nw  <B1-Motion> {resize_cp %W 1 %x %y}
	$::canvasstate::mycanvas bind tag_sw <1> {savepos %W %x %y}
	$::canvasstate::mycanvas bind tag_sw  <B1-Motion> {resize_cp %W 2 %x %y}
	$::canvasstate::mycanvas bind tag_ne <1> {savepos %W %x %y}
	$::canvasstate::mycanvas bind tag_ne  <B1-Motion> {resize_cp %W 3 %x %y}
	$::canvasstate::mycanvas bind tag_se <1> {savepos %W %x %y}
	$::canvasstate::mycanvas bind tag_se  <B1-Motion> {resize_cp %W 4 %x %y}

}

proc savepos {w x y} {
	set ::canvasstate::MoverX [$w canvasx $x]
    	set ::canvasstate::MoverY [$w canvasy $y]
}

proc DeActivateForResize {  } {
	foreach cp  $::canvasstate::control_points {
		$::canvasstate::mycanvas delete $cp
	}
	unset ::canvasstate::Id
	set ::canvasstate::control_points [list ]
}

proc resize_cp {w Id x y} {	
	set dx [expr {$x-$::canvasstate::MoverX} ]
	set dy [expr {$y-$::canvasstate::MoverY} ]
	set ::canvasstate::MoverX $x
	set ::canvasstate::MoverY $y
	if { $Id != 0 } {
		set target [lindex $::canvasstate::control_points $Id]
		$::canvasstate::mycanvas move $target $dx $dy
	}
	resize_rectangle $Id $dx $dy
}

proc resize_rectangle {Id dx dy} {
	switch $Id {		
		0 {Move_all $dx $dy}
		1 {Move_edge $dx $dy 2 3 }
		2 {Move_edge $dx $dy 1 4 }
		3 {Move_edge $dx $dy 4 1 }
		4 {Move_edge $dx $dy 3 2 }		
	}
}
	
proc Move_all {dx dy} {
	
	foreach target $::canvasstate::control_points {
		$::canvasstate::mycanvas move $target $dx $dy
	}
	
	set workingRectangle [lindex $::canvasstate::rectangles $::canvasstate::Id]
	$::canvasstate::mycanvas move [lindex $workingRectangle 0] $dx $dy
	$::canvasstate::mycanvas move [lindex $workingRectangle 1] $dx $dy
}

proc Move_edge {dx dy a b} {	
	set target [lindex $::canvasstate::control_points $a]
	$::canvasstate::mycanvas move $target $dx 0
	set target [lindex $::canvasstate::control_points $b]
	$::canvasstate::mycanvas move $target 0 $dy	
	redraw_rect $dx $dy
}

proc redraw_rect {dx dy} {
	
	set list1 [$::canvasstate::mycanvas coords [lindex $::canvasstate::control_points 1]]
	set list2 [$::canvasstate::mycanvas coords [lindex $::canvasstate::control_points 4]]
	
	set upx [expr {[lindex $list1 0] + 5}]
	set upy [expr {[lindex $list1 1] + 5}]
	set downx [expr {[lindex $list2 0] + 5}]
	set downy [expr {[lindex $list2 1] + 5}]
	
	set somecoords [list $upx $upy $downx $downy]
	
	set workingRectangle [lindex $::canvasstate::rectangles $::canvasstate::Id]
	$::canvasstate::mycanvas coords [lindex $workingRectangle 0] $somecoords
	set somecoords [list $upx [expr { $upy -15}]]
	$::canvasstate::mycanvas coords [lindex $workingRectangle 1] $somecoords
	
	set centerx [expr { $downx + $upx} ]
	set centerx [expr {$centerx / 2 }]
	set centery [expr { $downy + $upy} ]
	set centery [expr {$centery / 2 }]
	
	set somecoords [list [expr {$centerx -5} ] [expr {$centery -5} ] [expr {$centerx +5} ] [expr {$centery +5} ]]
	 $::canvasstate::mycanvas coords [lindex $::canvasstate::control_points 0] $somecoords	
}

proc arm_entry { state } {
	if {$state == 1} {
		.fpop.down.en configure  -state "normal"
	} else {
		.fpop.down.en configure  -state "readonly"
	}
	focus .fpop.but
}

proc dismiss_proc {  } {
	
	switch $::canvasstate::option_selection {
		1 { 
			DeleteCmd 
			unset ::canvasstate::Id
		}
		2 { 
			ActivateForResize
		}
		3 { 
			LabelCmd
			unset ::canvasstate::Id
		}
	}
	destroy .fpop
	focus .t.frameshow.canvas
	
}

