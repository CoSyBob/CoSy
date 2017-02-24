| Scene2 with some more utilities
| Reva OpenGL demo program
| Andrew Price, 2006

context: ~app

needs callbacks
needs util/auxstack 
needs math/floats
~floats
needs ui/gl  needs ui/glu  needs ui/glut
~gl
~app
variable tmpf32
2variable tmpf64
: f>32 tmpf32 f!4  tmpf32 @ ;
: f>64 tmpf64 f!8  tmpf64 2@ ;
: 3f f>32 f>32 f>32 rot rot swap ;     		| do 3 f>32s

: 3floats  create f>32 f>32 f>32 , , , ; 	| Initialised vector of 3 32bit floats
: 4floats  f>32 3floats , ;  		 	| Initialised vector of 4 32bit floats
: -f1 f1 fnegate ;				| -1.0 on TOFS

0 variable, noargs
: blankargs "  " ;
: windowtitle " GL Test -- Scene" ;
blankargs drop variable, blankargs*
500 variable, width
500 variable, height
f0 f0 f0 f1  4floats light_ambient drop
f1 f1 f1 f1  4floats light_diffuse drop
f1 f1 f1 f1  4floats light_specular drop
f1 f1 f1 f0  4floats light_position drop

variable mywindow
: init	noargs blankargs* glutInit drop
	GLUT_RGB GLUT_DOUBLE GLUT_DEPTH or or  glutInitDisplayMode drop
	width @ height @ glutInitWindowSize drop
	100 100 glutInitWindowPosition drop
	windowtitle drop glutCreateWindow mywindow !
	GL_LIGHT0 GL_AMBIENT light_ambient glLightfv drop
	GL_LIGHT0 GL_DIFFUSE light_diffuse glLightfv drop
	GL_LIGHT0 GL_SPECULAR light_specular glLightfv drop
	GL_LIGHT0 GL_POSITION light_position glLightfv drop
	GL_LIGHTING glEnable drop
	GL_LIGHT0 glEnable drop
	GL_DEPTH_TEST glEnable drop
;

fvariable posx fvariable posy fvariable posz
-f1 0.75e0 f* posx f!  0.5e0 posy f!  f0 posz f!
variable key

: HandleKey ( key x y -- )
| 3dup rot ." Key: " dup $ff and . ." (" emit ." ) x: " swap . ." y: " .
rot $ff and key ! 2drop  key @
|	 ." Key " rot dup dup key !  emit 32 emit . . . cr
	key @
	case
		'w of posy f@ 0.05e0 f+ posy f! endof | w
		's of posy f@ 0.05e0 f- posy f! endof | s
		'd of posx f@ 0.05e0 f+ posx f! endof | d
		'a of posx f@ 0.05e0 f- posx f! endof | a
		'q of posz f@ 0.05e0 f+ posz f! endof | q
		'e of posz f@ 0.05e0 f- posz f! endof | e
	endcase
	glutPostRedisplay drop ;	| ( key a b -- )

: HandleMouse  ." Mouse " . . . . cr ;



: DrawScene  | ." Draw" cr
	GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT or glClear drop
	GL_PROJECTION glMatrixMode drop
	glLoadIdentity drop
	-f1 2.5e0 f* f>64 2.5e0 f>64 -f1 2.5e0 f* f>64 2.5e0 f>64 -f1 10.0e0 f* f>64 10.0e0 f>64 glOrtho drop
	GL_MODELVIEW glMatrixMode drop
	glLoadIdentity drop
	glPushMatrix drop
	 20.0e0 f1 f0	3f f0 f>32 glRotatef drop
	 glPushMatrix drop
	  posx f@ posy f@ posz f@ 		3f glTranslatef drop
	  90.0e0 f>32 	f1 f0 f0	3f glRotatef drop
	  0.275e0 f>64 0.85e0 f>64 30 30 glutSolidTorus drop
	 glPopMatrix drop
	 glPushMatrix drop
	  -f1 0.75e0 f* f>32 -f1 0.5e0 f* f>32 0.0e0 f>32 glTranslatef drop
	  270.0e0 f>32 f1 f>32 f0 f>32 f0 f>32 glRotatef drop
	  1.0e0 f>64 2.0e0 f>64 15 15 glutSolidCone drop
	 glPopMatrix drop
	 glPushMatrix drop
	  0.75e0 f>32 0.0e0 f>32 -f1 f>32 glTranslatef
|	  1.0e0 f>64 30 30 glutSolidSphere
	  1.0e0 f>64 glutSolidTeapot
	 glPopMatrix drop
	glPopMatrix drop
	glFlush drop
	glutSwapBuffers drop
;


: Reshape ( width height -- )
   height ! width ! 					| ( width height -- )
	0 0 width @ height @ glViewport drop ." Reshape " width @ . height @ . cr
	GL_PROJECTION glMatrixMode drop
	glLoadIdentity drop
	-f1 2.5e0 f* f>64 2.5e0 f>64 -f1 2.5e0 f* f>64 2.5e0 f>64 -f1 10.0e0 f* f>64 10.0e0 f>64 glOrtho drop
	GL_MODELVIEW glMatrixMode drop
	glLoadIdentity drop

;

:: DrawScene ; 1024 	cb: SceneDrawer
:: 0 cb-param 1 cb-param 2 cb-param HandleKey ; 1024 	cb: KeyHandler
:: HandleMouse ; 1024 cb: MouseHandler
:: 0 cb-param 1 cb-param Reshape ; 1024 	cb: ReshapeHandler
: setup-callbacks 	['] SceneDrawer glutDisplayFunc drop 	['] KeyHandler glutKeyboardFunc drop
			['] MouseHandler glutMouseFunc drop 	['] ReshapeHandler glutReshapeFunc drop ;

init setup-callbacks glutMainLoop drop
