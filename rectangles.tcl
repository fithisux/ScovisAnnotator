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
source popupTester.tcl
package require xml 3.2

proc restore_paint_state { } {
	if { [info exists ::canvasstate::Id] } {		
		DeActivateForResize
	}
}

proc restore_canvas_state { } {
	puts "restore canvas state"
	set ::canvasstate::option_selection 3
	set ::canvasstate::prev_activity $::canvasstate::current_activity
	set ::canvasstate::current_activity "UnknownActivity"
	set ::canvasstate::label_selection "Label"
	set ::canvasstate::x 0
	set ::canvasstate::MoverX 0
	set ::canvasstate::MoverY 0
	set ::canvasstate::prev_rectangles [list ]
	set ::canvasstate::prev_text [list ]
	foreach somerectinfo $::canvasstate::rectangles {
		set rect_tag [lindex $somerectinfo 0]
		set somecoords [$::canvasstate::mycanvas coords $rect_tag]		
		set lab_tag [lindex $somerectinfo 1]
		set somename [$::canvasstate::mycanvas itemconfigure $lab_tag -text]
		set somename [lindex $somename 4]		
		set mydata [list]
		set mydata [linsert $mydata end $somecoords]
		set mydata [linsert $mydata end $somename]
		set ::canvasstate::prev_rectangles [linsert $::canvasstate::prev_rectangles end $mydata]
		
		$::canvasstate::mycanvas delete [lindex $somerectinfo 0]
		$::canvasstate::mycanvas delete [lindex $somerectinfo 1]		
	}
	set ::canvasstate::rectangles [list ]
	restore_paint_state
}


proc saveToXML {somenode} {

	set somenodes [dom::selectNode $somenode child::* ]
	
	foreach somechild $somenodes {
		::dom::node removeChild $somenode $somechild		
	}
	
	::dom::element setAttribute $somenode Activity $::canvasstate::current_activity 		
	
	foreach somerectinfo $::canvasstate::rectangles {
		set rect_tag [lindex $somerectinfo 0]
		set somecoords [$::canvasstate::mycanvas coords $rect_tag]
		set someId [lindex $somerectinfo 2]
		set data_node [::dom::document createElement $somenode AnnotationData ]
		::dom::element setAttribute $data_node "xup" [lindex $somecoords 0]
		::dom::element setAttribute $data_node "yup" [lindex $somecoords 1]
		::dom::element setAttribute $data_node "xdown" [lindex $somecoords 2]
		::dom::element setAttribute $data_node "ydown" [lindex $somecoords 3]
		::dom::element setAttribute $data_node "objectId" $someId		
	}
}

proc create_rectangle_XML {somenode} {	
	
	
	set somenodes [dom::selectNode $somenode child::* ]
	
	foreach somechild $somenodes {
		set xup [::dom::element getAttribute $somechild "xup"] 
		set yup [::dom::element getAttribute $somechild "yup"]
		set xdown [::dom::element getAttribute $somechild "xdown"]
		set ydown [::dom::element getAttribute $somechild "ydown"]
		set objectId [::dom::element getAttribute $somechild "objectId"] 		
		set somecoords [list $xup $yup $xdown $ydown]	
		create_rectangle $somecoords $objectId		
	}	
}

proc create_rectangle_normal {wherex wherey} {	
	if { [string length $::annotatorstate::current_file] == 0 } {		
		return				
	}
	if { [info exists ::canvasstate::Id] } {		
		return
	}
	
	set xdown [expr {$wherex + 32}] 
	set ydown [expr {$wherey + 32}]
		
	set somecoords [list $wherex $wherey $xdown $ydown]
	
	create_rectangle $somecoords "Unknown"	
}

proc create_rectangle { somecoords somename} {
	set  tagger1 "myrectangle$::canvasstate::x"
	set  tagger2 "mylabel$::canvasstate::x"
	
	set xup [lindex $somecoords 0]
	set yup [lindex $somecoords 1]
	set ytext [expr {$yup - 15}]
	
	$::canvasstate::mycanvas create rectangle $somecoords -tag $tagger1 -width 3 -outline white
	$::canvasstate::mycanvas create text $xup $ytext -text $somename -tag $tagger2	-fill white
	set unit_props [list $tagger1 $tagger2 $somename]
	set ::canvasstate::rectangles [linsert $::canvasstate::rectangles end $unit_props]
	set ::canvasstate::x [expr {$::canvasstate::x + 1}]
}


proc activate_rectangle {wherex wherey} {
	if { [info exists ::canvasstate::Id] } {
		DeActivateForResize
	}
	set idx 0
	foreach unit_prop $::canvasstate::rectangles {
		
		set rect_tag [lindex $unit_prop 0]
		set coord_list [$::canvasstate::mycanvas coords $rect_tag]
		set result [inside_rectangle $wherex $wherey $coord_list] 
		if {  $result == 1 } {
			popup_on_rectangle $idx
			return
		} else {
			set idx [expr {$idx + 1}]
		}
	}
}
