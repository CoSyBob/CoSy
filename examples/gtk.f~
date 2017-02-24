needs callbacks
needs ui/gtk
variable hwnd
variable button
with~ ~gtk

" gtk_widget_destroy" gtk in~ ~sys (func) variable, gtk_widget_destroy

:: gtk_main_quit ; 160 cb: destroy

: init 0 0 gtk_init ." Initializing GTK" drop ;

: start
	GTK_WINDOW_TOPLEVEL gtk_window_new hwnd !
	hwnd @ " destroy" drop 
	' destroy 0 gtk_signal_connect drop
	" Reva rocks!" drop gtk_button_new_with_label button !

	button @ " clicked" drop
		gtk_widget_destroy @
		hwnd @ gtk_signal_connect_object drop

	hwnd @ button @ gtk_container_add drop
	button @ gtk_widget_show drop
	hwnd @ gtk_widget_show drop
	gtk_main drop
	;

init start
." See 'ya later!" cr bye
