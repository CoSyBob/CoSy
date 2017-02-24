| Simple test for IUP + OpenGL
|
| Author: Danny Reinhold | Reinhold Software Services
| Reva's license terms also apply to this file

needs ui/gui
needs ui/gl
needs math/floats
~floats
~ui
~iup
~gl

:: ( params< self width height > -- continuationcode )
  0 cb-param dup >r
  gl-make-current drop


  0.6 f>32 0.6 f>32 0.6 f>32 1.0 f>32 glClearColor
  GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT or glClear

  1.0 f>32 0.0 f>32 0.0 f>32 glColor3f
  GL_LINES glBegin
    -0.5 f>32 0.2 f>32 glVertex2f
     0.5 f>32 0.2 f>32 glVertex2f
  glEnd

  1.0 f>32 1.0 f>32 0.0 f>32 glColor3f
  GL_QUADS glBegin
    0.9 f>32 0.9 f>32 glVertex2f
    0.7 f>32 0.9 f>32 glVertex2f
    0.7 f>32 0.7 f>32 glVertex2f
    0.9 f>32 0.7 f>32 glVertex2f
  glEnd

  0.0 f>32 0.0 f>32 1.0 f>32 glColor3f
  GL_POLYGON glBegin
    0.1 f>32 0.1 f>32 glVertex2f
    0.4 f>32 0.4 f>32 glVertex2f
    0.6 f>32 0.3 f>32 glVertex2f
    0.3 f>32 0.4 f>32 glVertex2f
  glEnd

  glFlush

  r>  gl-swap-buffers  drop

  gui-default
; 128 cb: redraw


: dlg
  dialog[
    spacer
    " This is a double buffered IupGLCanvas widget:" label[ ]w
    gl-canvas[ expand  action: redraw " DOUBLE" attr: BUFFER  " 123x200" attr: RASTERSIZE  ]w
    spacer
    hboxs[ " Quit!" button[ action[ gui-close ]a ]w  ]c
  ]d " IUP + OpenGL test" title
;


~
: go gui-init dlg show gui-main-loop destroy gui-release ;
exit~

exit~ | ~ui

go bye
